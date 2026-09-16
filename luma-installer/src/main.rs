//! Minimal installer custom actions: no interpreter, network, elevation or downloads.
use std::{fs, io::{self, Write}, path::{Path, PathBuf}};

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

trait Selection {
    fn get(&self) -> Result<Option<String>>;
    fn set(&mut self, value: Option<&str>) -> Result<()>;
}

fn read_previous(path: &Path) -> Result<Option<String>> {
    let bytes = fs::read(path)?;
    // Also accept BOMs emitted by older PowerShell versions.
    let bytes = bytes.strip_prefix(&[0xef, 0xbb, 0xbf]).unwrap_or(&bytes);
    let metadata: serde_json::Value = serde_json::from_slice(bytes)?;
    if metadata.get("schema").and_then(|v| v.as_u64()) != Some(1) {
        return Err("Unsupported installation metadata schema".into());
    }
    match metadata.get("previousScreenSaver") {
        Some(serde_json::Value::Null) => Ok(None),
        Some(serde_json::Value::String(value)) if !value.contains('\0') && value.len() <= 32767 => Ok(Some(value.clone())),
        _ => Err("Missing or invalid previous screensaver in installation metadata".into()),
    }
}

fn check_unlocked(binary: &Path) -> Result<()> {
    if binary.try_exists()? {
        let mut options = fs::OpenOptions::new();
        options.read(true).write(true);
        #[cfg(windows)]
        {
            use std::os::windows::fs::OpenOptionsExt;
            options.share_mode(0);
        }
        drop(options.open(binary)?);
    }
    Ok(())
}

fn prepare(directory: &Path, selection: &impl Selection) -> Result<()> {
    let binary = directory.join("Luma.scr");
    let manifest = directory.join("installation.json");
    check_unlocked(&binary)?;
    if manifest.try_exists()? {
        read_previous(&manifest)?;
        return Ok(()); // Preserve original selection across updates and ZIP migrations.
    }
    if binary.try_exists()? { return Err("Unmanaged Luma.scr found; move it before installing".into()); }
    let previous = selection.get()?;
    let metadata = serde_json::to_vec_pretty(&serde_json::json!({ "schema": 1, "previousScreenSaver": previous }))?;
    fs::create_dir_all(directory)?;
    let mut file = fs::OpenOptions::new().write(true).create_new(true).open(&manifest)?;
    if let Err(error) = file.write_all(&metadata).and_then(|_| file.sync_all()) {
        drop(file);
        let _ = fs::remove_file(&manifest);
        return Err(error.into());
    }
    Ok(())
}

fn restore(directory: &Path, selection: &mut impl Selection) -> Result<()> {
    let binary = directory.join("Luma.scr");
    check_unlocked(&binary)?;
    let previous = read_previous(&directory.join("installation.json"))?;
    let installed = binary.to_str().ok_or("Invalid installation path")?;
    if selection.get()?.is_some_and(|value| value.eq_ignore_ascii_case(installed)) {
        let previous = previous.filter(|value| !value.is_empty() && expand_environment(value).is_file());
        selection.set(previous.as_deref())?;
    }
    Ok(())
}

#[cfg(windows)]
fn wide(value: &str) -> Vec<u16> { value.encode_utf16().chain(Some(0)).collect() }

#[cfg(windows)]
fn expand_environment(value: &str) -> PathBuf {
    use windows_sys::Win32::System::Environment::ExpandEnvironmentStringsW;
    let input = wide(value);
    unsafe {
        let size = ExpandEnvironmentStringsW(input.as_ptr(), std::ptr::null_mut(), 0);
        if size == 0 { return PathBuf::from(value); }
        let mut buffer = vec![0; size as usize];
        let written = ExpandEnvironmentStringsW(input.as_ptr(), buffer.as_mut_ptr(), size);
        if written == 0 || written > size { return PathBuf::from(value); }
        PathBuf::from(String::from_utf16_lossy(&buffer[..written as usize - 1]))
    }
}

#[cfg(not(windows))]
fn expand_environment(value: &str) -> PathBuf { value.into() }

#[cfg(windows)]
struct WindowsSelection;

#[cfg(windows)]
impl Selection for WindowsSelection {
    fn get(&self) -> Result<Option<String>> {
        use windows_sys::Win32::System::Registry::*;
        let key = wide("Control Panel\\Desktop");
        let name = wide("SCRNSAVE.EXE");
        let flags = RRF_RT_REG_SZ | RRF_RT_REG_EXPAND_SZ;
        unsafe {
            let mut size = 0;
            let status = RegGetValueW(HKEY_CURRENT_USER, key.as_ptr(), name.as_ptr(), flags, std::ptr::null_mut(), std::ptr::null_mut(), &mut size);
            if status == 2 { return Ok(None); } // ERROR_FILE_NOT_FOUND
            if status != 0 { return Err(io::Error::from_raw_os_error(status as i32).into()); }
            let mut buffer = vec![0u16; (size as usize + 1) / 2];
            let status = RegGetValueW(HKEY_CURRENT_USER, key.as_ptr(), name.as_ptr(), flags, std::ptr::null_mut(), buffer.as_mut_ptr().cast(), &mut size);
            if status != 0 { return Err(io::Error::from_raw_os_error(status as i32).into()); }
            let end = buffer.iter().position(|&c| c == 0).unwrap_or(buffer.len());
            Ok(Some(String::from_utf16(&buffer[..end])?))
        }
    }

    fn set(&mut self, value: Option<&str>) -> Result<()> {
        use windows_sys::Win32::System::Registry::*;
        let key_name = wide("Control Panel\\Desktop");
        let name = wide("SCRNSAVE.EXE");
        unsafe {
            let mut key = std::ptr::null_mut();
            let status = RegOpenKeyExW(HKEY_CURRENT_USER, key_name.as_ptr(), 0, KEY_SET_VALUE, &mut key);
            if status != 0 { return Err(io::Error::from_raw_os_error(status as i32).into()); }
            let status = if let Some(value) = value {
                let value = wide(value);
                RegSetValueExW(key, name.as_ptr(), 0, REG_SZ, value.as_ptr().cast(), (value.len() * 2) as u32)
            } else {
                let status = RegDeleteValueW(key, name.as_ptr());
                if status == 2 { 0 } else { status }
            };
            RegCloseKey(key);
            if status != 0 { return Err(io::Error::from_raw_os_error(status as i32).into()); }
        }
        Ok(())
    }
}

#[cfg(windows)]
fn run() -> Result<()> {
    let arguments: Vec<_> = std::env::args_os().skip(1).collect();
    if arguments.len() != 2 { return Err("Usage: luma-install-helper.exe Prepare|Restore <absolute-install-directory>".into()); }
    let directory = PathBuf::from(&arguments[1]);
    if !directory.is_absolute() { return Err("Installation directory must be absolute".into()); }
    let mut selection = WindowsSelection;
    match arguments[0].to_str() {
        Some("Prepare") => prepare(&directory, &selection),
        Some("Restore") => restore(&directory, &mut selection),
        _ => Err("Unknown installer action".into()),
    }
}

#[cfg(not(windows))]
fn run() -> Result<()> { Err("Luma installation requires Windows".into()) }

fn main() {
    if let Err(error) = run() {
        eprintln!("Luma installer: {error}");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};
    static NEXT: AtomicUsize = AtomicUsize::new(0);

    struct Fixture(PathBuf);
    impl Fixture {
        fn new() -> Self {
            let path = std::env::temp_dir().join(format!("luma-helper-test-{}-{}", std::process::id(), NEXT.fetch_add(1, Ordering::Relaxed)));
            fs::create_dir(&path).unwrap();
            Self(path)
        }
    }
    impl Drop for Fixture {
        fn drop(&mut self) {
            for name in ["Luma.scr", "installation.json", "previous.scr"] { let _ = fs::remove_file(self.0.join(name)); }
            let _ = fs::remove_dir(&self.0);
        }
    }
    struct FakeSelection(Option<String>);
    impl Selection for FakeSelection {
        fn get(&self) -> Result<Option<String>> { Ok(self.0.clone()) }
        fn set(&mut self, value: Option<&str>) -> Result<()> { self.0 = value.map(str::to_owned); Ok(()) }
    }

    #[test]
    fn preserves_original_on_update_and_restores_it() {
        let fixture = Fixture::new();
        let previous = fixture.0.join("previous.scr");
        fs::write(&previous, b"previous").unwrap();
        let mut selection = FakeSelection(Some(previous.to_str().unwrap().into()));
        prepare(&fixture.0, &selection).unwrap();
        fs::write(fixture.0.join("Luma.scr"), b"app").unwrap();
        selection.0 = Some(fixture.0.join("Luma.scr").to_str().unwrap().into());
        prepare(&fixture.0, &selection).unwrap();
        restore(&fixture.0, &mut selection).unwrap();
        assert_eq!(selection.0.as_deref(), previous.to_str());
    }

    #[test]
    fn preserves_newer_selection() {
        let fixture = Fixture::new();
        let mut selection = FakeSelection(None);
        prepare(&fixture.0, &selection).unwrap();
        selection.0 = Some("another.scr".into());
        restore(&fixture.0, &mut selection).unwrap();
        assert_eq!(selection.0.as_deref(), Some("another.scr"));
    }

    #[test]
    fn restores_missing_or_deleted_previous_to_none() {
        for previous in [None, Some("Z:\\does-not-exist.scr".into())] {
            let fixture = Fixture::new();
            let mut selection = FakeSelection(previous);
            prepare(&fixture.0, &selection).unwrap();
            selection.0 = Some(fixture.0.join("Luma.scr").to_str().unwrap().into());
            restore(&fixture.0, &mut selection).unwrap();
            assert_eq!(selection.0, None);
        }
    }

    #[test]
    fn rejects_unmanaged_binary_and_corrupt_metadata_without_changing_selection() {
        let fixture = Fixture::new();
        let mut selection = FakeSelection(Some("original.scr".into()));
        fs::write(fixture.0.join("Luma.scr"), b"unmanaged").unwrap();
        assert!(prepare(&fixture.0, &selection).is_err());
        assert!(!fixture.0.join("installation.json").exists());
        for data in ["bad json", r#"{"schema":2,"previousScreenSaver":null}"#, r#"{"schema":1}"#, r#"{"schema":1,"previousScreenSaver":123}"#] {
            fs::write(fixture.0.join("installation.json"), data).unwrap();
            assert!(prepare(&fixture.0, &selection).is_err());
            assert!(restore(&fixture.0, &mut selection).is_err());
            assert_eq!(selection.0.as_deref(), Some("original.scr"));
        }
    }

    #[test]
    fn accepts_existing_powershell_metadata_with_bom_and_unicode() {
        let fixture = Fixture::new();
        let data = "\u{feff}{\r\n  \"schema\": 1,\r\n  \"previousScreenSaver\": \"C:\\\\schermi\\\\città.scr\"\r\n}";
        let manifest = fixture.0.join("installation.json");
        fs::write(&manifest, data).unwrap();
        assert_eq!(read_previous(&manifest).unwrap().as_deref(), Some("C:\\schermi\\città.scr"));
        prepare(&fixture.0, &FakeSelection(None)).unwrap();
        assert_eq!(fs::read_to_string(manifest).unwrap(), data);
    }

    #[cfg(windows)]
    #[test]
    fn locked_binary_blocks_prepare_and_restore_without_registry_changes() {
        use std::os::windows::fs::OpenOptionsExt;
        let fixture = Fixture::new();
        let mut selection = FakeSelection(None);
        prepare(&fixture.0, &selection).unwrap();
        let binary = fixture.0.join("Luma.scr");
        fs::write(&binary, b"app").unwrap();
        selection.0 = Some(binary.to_str().unwrap().into());
        let _lock = fs::OpenOptions::new().read(true).share_mode(0).open(&binary).unwrap();
        assert!(prepare(&fixture.0, &selection).is_err());
        assert!(restore(&fixture.0, &mut selection).is_err());
        assert_eq!(selection.0.as_deref(), binary.to_str());
    }
}

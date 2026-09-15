use std::time::Duration;

pub fn input_armed(since_first_frame: Option<Duration>) -> bool {
    since_first_frame.is_some_and(|elapsed| elapsed >= Duration::from_secs(2))
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Mode {
    Desktop,
    Saver,
    Configure,
    Preview,
}

impl Mode {
    pub fn parse(args: &[String], is_scr: bool) -> Result<Self, &'static str> {
        let Some(first) = args.first() else {
            return Ok(if is_scr {
                Self::Configure
            } else {
                Self::Desktop
            });
        };
        let flag = first.to_ascii_lowercase();
        match flag.as_str() {
            "--windowed" if args.len() == 1 => Ok(Self::Desktop),
            "/s" | "-s" if args.len() == 1 => Ok(Self::Saver),
            "/c" | "-c" => Ok(Self::Configure),
            "/p" | "-p" => Ok(Self::Preview),
            _ if flag.starts_with("/c:") || flag.starts_with("-c:") => Ok(Self::Configure),
            _ if flag.starts_with("/p:") || flag.starts_with("-p:") => Ok(Self::Preview),
            _ => Err("Argomento non riconosciuto. Usa /s per lo screensaver o --windowed per il prototipo."),
        }
    }
}

#[derive(Default)]
pub struct MouseExit {
    origin: Option<(f64, f64)>,
}

impl MouseExit {
    pub fn moved(&mut self, elapsed: Duration, x: f64, y: f64) -> bool {
        // Ignore synthetic startup motion and give the launch click time to settle.
        if elapsed < Duration::from_secs(2) {
            self.origin = Some((x, y));
            return false;
        }
        let (ox, oy) = *self.origin.get_or_insert((x, y));
        (x - ox).hypot(y - oy) >= 8.0
    }
}

pub fn show_message(message: &str) {
    #[cfg(target_os = "windows")]
    {
        let title: Vec<u16> = "Luma\0".encode_utf16().collect();
        let text: Vec<u16> = message.encode_utf16().chain(Some(0)).collect();
        // Both strings are null-terminated and live until MessageBoxW returns.
        unsafe {
            windows_sys::Win32::UI::WindowsAndMessaging::MessageBoxW(
                std::ptr::null_mut(),
                text.as_ptr(),
                title.as_ptr(),
                windows_sys::Win32::UI::WindowsAndMessaging::MB_OK,
            );
        }
    }
    #[cfg(not(target_os = "windows"))]
    eprintln!("Luma: {message}");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn startup_keyboard_events_cannot_exit_before_first_frame_or_during_grace() {
        assert!(!input_armed(None));
        assert!(!input_armed(Some(Duration::ZERO)));
        assert!(!input_armed(Some(Duration::from_millis(1999))));
        assert!(input_armed(Some(Duration::from_secs(2))));
    }

    fn parse(args: &[&str], scr: bool) -> Result<Mode, &'static str> {
        Mode::parse(&args.iter().map(|s| s.to_string()).collect::<Vec<_>>(), scr)
    }

    #[test]
    fn launch_modes_are_case_insensitive_and_safe_for_preview() {
        assert_eq!(parse(&[], false), Ok(Mode::Desktop));
        assert_eq!(parse(&[], true), Ok(Mode::Configure));
        for flag in ["/s", "/S", "-s"] {
            assert_eq!(parse(&[flag], true), Ok(Mode::Saver));
        }
        assert_eq!(parse(&["/P", "1234"], true), Ok(Mode::Preview));
        assert_eq!(parse(&["/p:1234"], true), Ok(Mode::Preview));
        assert_eq!(parse(&["/C:1234"], true), Ok(Mode::Configure));
        assert_eq!(parse(&["--windowed"], true), Ok(Mode::Desktop));
        assert!(parse(&["/unknown"], true).is_err());
    }

    #[test]
    fn mouse_ignores_startup_and_jitter_but_accumulates_motion() {
        let mut mouse = MouseExit::default();
        assert!(!mouse.moved(Duration::ZERO, 100.0, 100.0));
        assert!(!mouse.moved(Duration::from_millis(500), 200.0, 200.0));
        assert!(!mouse.moved(Duration::from_secs(2), 203.0, 201.0));
        assert!(mouse.moved(Duration::from_secs(2), 208.0, 200.0));
        let mut mouse = MouseExit::default();
        assert!(!mouse.moved(Duration::from_secs(2), 500.0, 500.0));
        assert!(mouse.moved(Duration::from_secs(2), 510.0, 500.0));
    }
}

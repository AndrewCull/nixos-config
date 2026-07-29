{ ... }:
{
  services.wlsunset = {
    enable = true;
    output = "eDP-1";
    sunrise = "07:00";
    sunset = "20:00";
    duration = 1800;  # 30 min easing; required with sunrise/sunset mode since HM 2026-07
    temperature = {
      day = 6500;
      night = 4000;
    };
  };
}

{ ... }:
{
  services.wlsunset = {
    enable = true;
    output = "eDP-1";
    sunrise = "07:00";
    sunset = "20:00";
    temperature = {
      day = 6500;
      night = 4000;
    };
  };
}

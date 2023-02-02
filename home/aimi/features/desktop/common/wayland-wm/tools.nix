{ pkgs, ... }: {
  home.packages = with pkgs; [
    ## screenshot
    grim
    slurp
    wl-clipboard
    wf-recorder
    ## another choice for change img
    swappy
    ## screen sharing
    pipewire
    pamixer
    wireplumber
  ];
}

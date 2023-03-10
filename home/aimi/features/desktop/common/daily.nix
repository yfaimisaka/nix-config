{ pkgs, ... }: {
  home.packages = with pkgs; [
    qq
    feishu
    chromium
    # telegram desktop
    tdesktop
    # change light of screen 
    brightnessctl
    # office tool
    mdds # dependency for libreoffice
    libreoffice
    # martrix client
    # use weechat-martrix instead
    #element-desktop
    
    # overlay: weechat with scripts
    weechat-with-scripts

    # Vector graphics editor
    inkscape

    # ebook reader
    calibre
    # The GNU Image Manipulation Program
    gimp
  ];
}

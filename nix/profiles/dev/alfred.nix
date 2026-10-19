# Alfred on Cmd-Space: takes the shortcut away from Spotlight and makes it
# Alfred's hotkey.
{ lib, pkgs, ... }:

let
  # macOS symbolic hotkey 64 is "Show Spotlight search"; this is the entry
  # macOS itself writes when you untick it (Space: char 32, key code 49;
  # Cmd: 1048576). Finder's search window (65, Opt-Cmd-Space) is untouched.
  spotlightOff = "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>";

  # Alfred's main hotkey, in the format Alfred 5 stores it.
  alfredHotkey = pkgs.writeText "alfred-hotkey-prefs.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>default</key>
      <dict>
        <key>key</key>
        <integer>49</integer>
        <key>mod</key>
        <integer>1048576</integer>
        <key>string</key>
        <string> </string>
      </dict>
    </dict>
    </plist>
  '';
in
{
  # Every step is non-fatal: a shortcut tweak must never stop the rest of
  # the activation.
  home.activation.alfredHotkey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '${spotlightOff}' ||
      echo "alfredHotkey: could not turn off Spotlight's Cmd-Space" >&2
    # Applies changed keyboard shortcuts without logging out (a private
    # macOS tool; without it they apply at next login).
    activate=/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings
    if [ -x "$activate" ]; then run "$activate" -u || true; fi

    # Alfred keeps the hotkey per machine, in preferences/local/<id>/ of its
    # preferences folder (a sync folder, if one is set). The <id> folder
    # appears on Alfred's first launch, so this takes effect from the
    # rebuild after that; restart Alfred to pick it up.
    alfred_prefs="$(/usr/bin/defaults read com.runningwithcrayons.Alfred-Preferences syncfolder 2>/dev/null || true)"
    alfred_prefs="''${alfred_prefs/#\~/$HOME}"
    alfred_prefs="''${alfred_prefs:-$HOME/Library/Application Support/Alfred}/Alfred.alfredpreferences/preferences/local"
    for dir in "$alfred_prefs"/*/; do
      [ -d "$dir" ] || continue
      { run mkdir -p "$dir/hotkey" && run install -m 0644 ${alfredHotkey} "$dir/hotkey/prefs.plist"; } ||
        echo "alfredHotkey: could not set Alfred's hotkey in $dir" >&2
    done
  '';
}

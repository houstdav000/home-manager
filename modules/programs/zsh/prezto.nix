{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.programs.zsh.prezto;

  preztoModule = types.submodule {
    options = {
      enable = mkEnableOption "prezto";

      package = mkPackageOption pkgs "prezto" { };

      caseSensitive = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Set case-sensitivity for completion, history lookup, etc.
        '';
      };

      color = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable color output globally (will auto set to 'no' on dumb terminals)
        '';
      };

      pmoduleDirs = mkOption {
        type = with types; listOf path;
        default = [ ];
        example = [ "$HOME/.zprezto-contrib" ];
        description = ''
          Add additional directories to load prezto modules from.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional configuration to add to <filename>.zpreztorc</filename>.
        '';
      };

      extraModules = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "attr" "stat" ];
        description = ''
          Set the Zsh modules to load (man zshmodules).
        '';
      };

      extraFunctions = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "zargs" "zmv" ];
        description = ''
          Set the Zsh functions to load (man zshcontrib).
        '';
      };

      pmodules = mkOption {
        type = with types; listOf str;
        default = [
          "environment"
          "terminal"
          "editor"
          "history"
          "directory"
          "spectrum"
          "utility"
          "completion"
          "prompt"
        ];
        description = ''
          Set the Prezto modules to load (browse modules). The order matters.
        '';
      };

      autosuggestions.color = mkOption {
        type = types.str;
        default = "";
        example = "fg=blue";
        description = ''
          Set the "query found" highlight color for zsh-autosuggestions.
        '';
      };

      completions.ignoredHosts = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "0.0.0.0" "127.0.0.1" ];
        description = ''
          Set the entries to ignore in static */etc/hosts* for host completion.
        '';
      };

      editor = {
        keymap = mkOption {
          type = types.enum [ "emacs" "viins" "vicmd" ];
          default = "emacs";
          example = "viins";
          description = ''
            Set the key mapping style to 'emacs', 'viins', or 'vicmd'.
          '';
        };

        dotExpansion = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Auto convert .... to ../..
          '';
        };

        promptContext = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Allow the zsh prompt context to be shown.
          '';
        };
      };

      git.submoduleIgnore = mkOption {
        type = types.enum [ "dirty" "untracked" "all" "none" ];
        default = "none";
        example = "all";
        description = ''
          Ignore submodules when they are 'dirty', 'untracked', 'all', or 'none'.
        '';
      };

      gnuUtility.prefix = mkOption {
        type = types.str;
        default = "g";
        description = ''
          Set the command prefix on non-GNU systems.
        '';
      };

      # NOTE: Defaults from https://github.com/sorin-ionescu/prezto/blob/f7cb1fee1b5d45df07d141c1f10d9286f98fb8de/modules/history-substring-search/init.zsh
      historySubstring = {
        foundColor = mkOption {
          type = types.str;
          default = "bg=magenta,fg=white,bold";
          example = "fg=blue";
          description = ''
            Set the query "found" color highlight.
          '';
        };

        notFoundColor = mkOption {
          type = types.str;
          default = "bg=red,fg=white,bold";
          example = "fg=red";
          description = ''
            Set the query "not found" color highlight.
          '';
        };

        globbingFlags = mkOption {
          type = types.str;
          default = "i";
          description = ''
            Set the search globbing flags.
          '';
        };
      };

      macOS.dashKeyword = mkOption {
        type = types.str;
        default = "manpages";
        description = ''
          Set the keyword used by `mand` to open man pages in Dash.app
        '';
      };

      prompt = {
        theme = mkOption {
          type = types.str;
          default = "sorin";
          example = "pure";
          description = ''
            Set the prompt theme to load. Setting it to 'random'
            loads a random theme. Auto set to 'off' on dumb terminals.
          '';
        };

        pwdLength = mkOption {
          type = types.enum [ "short" "long" "full" ];
          default = "short";
          example = "long";
          description = ''
            Set the working directory prompt display length. By
            default, it is set to 'short'. Set it to 'long' (without '~' expansion) for
            longer or 'full' (with '~' expansion) for even longer prompt display.
          '';
        };

        showReturnVal = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Set the prompt to display the return code along with an
            indicator for non-zero return codes. This is not supported by all prompts.
          '';
        };
      };

      python = {
        virtualenvAutoSwitch = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Auto switch to Python virtualenv on directory change.
          '';
        };

        virtualenvInitialize = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Automatically initialize virtualenvwrapper if pre-requisites are met.
          '';
        };
      };

      ruby.chrubyAutoSwitch = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Auto switch the Ruby version on directory change.
        '';
      };

      screen = {
        autoStartLocal = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Auto start a session when Zsh is launched in a local terminal.
          '';
        };

        autoStartRemote = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Auto start a session when Zsh is launched in a SSH connection.
          '';
        };
      };

      ssh.identities = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "id_rsa" "id_rsa2" "id_github" ];
        description = ''
          Set the SSH identities to load into the agent.
        '';
      };

      syntaxHighlighting = {
        highlighters = mkOption {
          type = with types; listOf str;
          default = [ "main" ];
          example = [ "main" "brackets" "pattern" "line" "cursor" "root" ];
          description = ''
            Set syntax highlighters. By default, only the main
            highlighter is enabled.
          '';
        };

        styles = mkOption {
          type = with types; attrsOf str;
          default = { };
          example = {
            builtin = "bg=blue";
            command = "bg=blue";
            function = "bg=blue";
          };
          description = ''
            Set syntax highlighting styles.
          '';
        };

        pattern = mkOption {
          type = with types; attrsOf str;
          default = { };
          example = { "rm*-rf*" = "fg=white,bold,bg=red"; };
          description = ''
            Set syntax pattern styles.
          '';
        };
      };

      terminal = {
        autoTitle = mkOption {
          type = types.enum [ "no" "yes" "always" ];
          default = "no";
          description = ''
            Auto set the tab and window titles.
          '';
        };

        windowTitleFormat = mkOption {
          type = types.str;
          default = "%s";
          example = "%n@%m: %s";
          description = ''
            Set the window title format.
          '';
        };

        tabTitleFormat = mkOption {
          type = types.str;
          default = "%s";
          example = "%m: %s";
          description = ''
            Set the tab title format.
          '';
        };

        multiplexerTitleFormat = mkOption {
          type = types.str;
          default = "%s";
          description = ''
            Set the multiplexer title format.
          '';
        };
      };

      tmux = {
        autoStartLocal = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Auto start a session when Zsh is launched in a local terminal.
          '';
        };

        autoStartRemote = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Auto start a session when Zsh is launched in a SSH connection.
          '';
        };

        itermIntegration = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Integrate with iTerm2.
          '';
        };

        defaultSessionName = mkOption {
          type = types.str;
          default = "prezto";
          example = "YOUR DEFAULT SESSION NAME";
          description = ''
            Set the default session name.
          '';
        };
      };

      utility.safeOps = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enabled safe options. This aliases cp, ln, mv and rm so
          that they prompt before deleting or overwriting files. Set to 'no'
          to disable this safer behavior.
        '';
      };
    };
  };
in {
  options = {
    programs.zsh.prezto = mkOption {
      type = preztoModule;
      default = { };
      description = "Options to configure prezto.";
    };
  };

  config = let
    relToDotDir = file:
      "${
        optionalString (config.programs.zsh.dotDir != null)
        "${config.programs.zsh.dotDir}/"
      }${file}";
    zconfigFiles = [ "zprofile" "zlogin" "zlogout" "zshenv" ];
    mapListToAttrs' = f: list: listToAttrs (map f list);
    concatLines = lib.concatLines or concatStringsSep "\n";
    splat = foldl' id;

    mkSettingsCmd = contextPath: n: v:
      optionalString
      (!((isList v && v == [ ]) || (isAttrs v && v == { }) || (v == null)))
      "zstyle '${contextPath}' ${n} ${
        escapeShellArgs (if isAttrs v then
          mapAttrsToList (n: v: "${n} ${v}") v
        else
          toList (if isBool v then lib.hm.booleans.yesNo v else toString v))
      }";
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = (mapListToAttrs' (v:
      nameValuePair (relToDotDir ".${v}")
      "${cfg.package}/share/zsh-prezto/runcoms/${v}") zconfigFiles) // {

        "${relToDotDir ".zpreztorc"}".text = ''
          # Generated by home-manager
          ${concatMap (splat mkSettingsCmd) [
            [ ":prezto:*:*" "case-sensitive" cfg.caseSensitive ]
            [ ":prezto:*:*" "color" cfg.color ]
            [ ":prezto:load" "pmodule-dirs" cfg.pmoduleDirs ]
            [ ":prezto:load" "zmodule" cfg.extraModules ]
            [ ":prezto:load" "zfunction" cfg.extraFunctions ]
            [ ":prezto:load" "pmodule" cfg.pmodules ]
            [
              ":prezto:module:completion:*:hosts"
              "etc-host-ignores"
              cfg.completions.ignoredHosts
            ]
            [
              ":prezto:module:autosuggestions:color"
              "found"
              cfg.autosuggestions.color
            ]
            [ ":prezto:module:editor" "key-bindings" cfg.editor.keymap ]
            [ ":prezto:module:editor" "dot-expansion" cfg.editor.dotExpansion ]
            [ ":prezto:module:editor" "ps-context" cfg.editor.promptContext ]
            [
              ":prezto:module:git:status:ignore"
              "submodules"
              cfg.git.submoduleIgnore
            ]
            [ ":prezto:module:gnu-utility" "prefix" cfg.gnuUtility.prefix ]
            [
              ":prezto:module:history-substring-search:color"
              "found"
              cfg.historySubstring.foundColor
            ]
            [
              ":prezto:module:history-substring-search:color"
              "not-found"
              cfg.historySubstring.notFoundColor
            ]
            [
              ":prezto:module:history-substring-search:color"
              "globbing-flags"
              cfg.historySubstring.globbingFlags
            ]
            [ ":prezto:module:osx:man" "dash-keyword" cfg.macOS.dashKeyword ]
            [ ":prezto:module:prompt" "theme" cfg.prompt.theme ]
            [ ":prezto:module:prompt" "pwd-length" cfg.prompt.pwdLength ]
            [
              ":prezto:module:prompt"
              "show-return-val"
              cfg.prompt.showReturnVal
            ]
            [
              ":prezto:module:python:virtualenv"
              "auto-switch"
              cfg.python.virtualenvAutoSwitch
            ]
            [
              ":prezto:module:python:virtualenv"
              "initialize"
              cfg.python.virtualenvInitialize
            ]
            [
              ":prezto:module:ruby:chruby"
              "auto-switch"
              cfg.ruby.chrubyAutoSwitch
            ]
            [
              ":prezto:module:screen:auto-start"
              "local"
              cfg.screen.autoStartLocal
            ]
            [
              ":prezto:module:screen:auto-start"
              "remote"
              cfg.screen.autoStartRemote
            ]
            [ ":prezto:module:ssh:load" "identities" cfg.ssh.identities ]
            [
              ":prezto:module:syntax-highlighting"
              "highlighters"
              cfg.syntaxHighlighting.highlighters
            ]
            [
              ":prezto:module:syntax-highlighting"
              "styles"
              cfg.syntaxHighlighting.styles
            ]
            [
              ":prezto:module:syntax-highlighting"
              "pattern"
              cfg.syntaxHighlighting.pattern
            ]
            [ ":prezto:module:terminal" "auto-title" cfg.terminal.autoTitle ]
            [
              ":prezto:module:terminal:window-title"
              "format"
              cfg.terminal.windowTitleFormat
            ]
            [
              ":prezto:module:terminal:tab-title"
              "format"
              cfg.terminal.tabTitleFormat
            ]
            [
              ":prezto:module:terminal:multiplexer-title"
              "format"
              cfg.terminal.multiplexerTitleFormat
            ]
            [ ":prezto:module:tmux:auto-start" "local" cfg.tmux.autoStartLocal ]
            [
              ":prezto:module:tmux:auto-start"
              "remote"
              cfg.tmux.autoStartRemote
            ]
            [
              ":prezto:module:tmux:iterm"
              "integrate"
              cfg.tmux.itermIntegration
            ]
            [ ":prezto:module:tmux:session" "name" cfg.tmux.defaultSessionName ]
            [ ":prezto:module:utility" "safe-ops" cfg.utility.safeOps ]
          ]}
          ${cfg.extraConfig}
        '';
      };
  };
}

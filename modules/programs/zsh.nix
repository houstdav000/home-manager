{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zsh;

  concatLines = lib.concatLines or concatStringsSep "\n";
  mapListToAttrs' = f: list: listToAttrs (map f list);

  relToDotDir = file: "${optionalString (cfg.dotDir != null) "${cfg.dotDir}/"}${file}";

  # pluginsDir = if cfg.dotDir != null then
  #   relToDotDir "plugins" else ".zsh/plugins";
  pluginsDir = "${cfg.dotDir or ".zsh"}/plugins";

  zdotdir = "$HOME/${cfg.dotDir}";

  bindkeyCommands = {
    emacs = "bindkey -e";
    viins = "bindkey -v";
    vicmd = "bindkey -a";
  };

  stateVersion = config.home.stateVersion;

  historyModule = types.submodule ({ config, ... }: {
    options = {
      size = mkOption {
        type = types.ints.unsigned;
        default = 10000;
        description = ''
          Number of history lines to keep.
        '';
      };

      save = mkOption {
        type = types.ints.unsigned;
        defaultText = 10000;
        default = config.size or 10000;
        description = ''
          Number of history lines to save.
        '';
      };

      path = mkOption {
        type = types.str;
        default = if versionAtLeast stateVersion "20.03"
          then "$HOME/.zsh_history"
          else relToDotDir ".zsh_history";
        defaultText = literalExpression ''
          "$HOME/.zsh_history" if state version ≥ 20.03,
          "$ZDOTDIR/.zsh_history" otherwise
        '';
        example = literalExpression ''"''${config.xdg.dataHome}/zsh/zsh_history"'';
        description = ''
          History file location
        '';
      };

      ignorePatterns = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''[ "rm *" "pkill *" ]'';
        description = ''
          Do not enter command lines into the history list
          if they match any one of the given shell patterns.
        '';
      };

      ignoreDups = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Do not enter command lines into the history list
          if they are duplicates of the previous event.
        '';
      };

      ignoreSpace = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Do not enter command lines into the history list
          if the first character is a space.
        '';
      };

      expireDuplicatesFirst = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Expire duplicates first.
        '';
      };

      extended = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Save timestamp into the history file.
        '';
      };

      share = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Share command history between zsh sessions.
        '';
      };
    };
  });

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      src = mkOption {
        type = types.path;
        description = ''
          Path to the plugin folder.

          Will be added to <envar>fpath</envar> and <envar>PATH</envar>.
        '';
      };

      name = mkOption {
        type = types.str;
        description = ''
          The name of the plugin.

          Don't forget to add <option>file</option>
          if the script name does not follow convention.
        '';
      };

      file = mkOption {
        type = types.str;
        description = "The plugin script to source.";
      };
    };

    config.file = mkDefault "${config.name}.plugin.zsh";
  });

  ohMyZshModule = types.submodule {
    options = {
      enable = mkEnableOption "oh-my-zsh";

      package = mkPackageOption pkgs "oh-my-zsh" { };

      plugins = mkOption {
        default = [ ];
        example = [ "git" "sudo" ];
        type = types.listOf types.str;
        description = ''
          List of oh-my-zsh plugins
        '';
      };

      custom = mkOption {
        default = "";
        type = types.str;
        example = "$HOME/my_customizations";
        description = ''
          Path to a custom oh-my-zsh package to override config of
          oh-my-zsh. See <link xlink:href="https://github.com/robbyrussell/oh-my-zsh/wiki/Customization"/>
          for more information.
        '';
      };

      theme = mkOption {
        default = "";
        example = "robbyrussell";
        type = types.str;
        description = ''
          Name of the theme to be used by oh-my-zsh.
        '';
      };

      extraConfig = mkOption {
        default = "";
        example = ''
          zstyle :omz:plugins:ssh-agent identities id_rsa id_rsa2 id_github
        '';
        type = types.lines;
        description = ''
          Extra settings for plugins.
        '';
      };
    };
  };

  historySubstringSearchModule = types.submodule {
    options = {
      enable = mkEnableOption "history substring search";

      package = mkPackageOption pkgs "zsh-history-substring-search" { };

      searchUpKey = mkOption {
        type = types.str;
        default = "^[[A";
        description = ''
          The key code to be used when searching up.
          The default of <literal>^[[A</literal> corresponds to the UP key.
        '';
      };

      searchDownKey = mkOption {
        type = types.str;
        default = "^[[B";
        description = ''
          The key code to be used when searching down.
          The default of <literal>^[[B</literal> corresponds to the DOWN key.
        '';
      };
    };
  };
in {
  options = {
    programs.zsh = {
      enable = mkEnableOption "Z shell (Zsh)";

      package = mkPackageOption pkgs "zsh" { };

      autocd = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          Automatically enter into a directory if typed directly into shell.
        '';
      };

      cdpath = mkOption {
        type = with types; listOf str;
        default = [ ];
        description = ''
          List of paths to autocomplete calls to `cd`.
        '';
      };

      dotDir = mkOption {
        type = with types; nullOr str;
        default = null;
        example = ".config/zsh";
        description = ''
          Directory where the zsh configuration and more should be located,
          relative to the users home directory. The default is the home
          directory.
        '';
      };

      shellAliases = mkOption {
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            ll = "ls -l";
            ".." = "cd ..";
          }
        '';
        description = ''
          An attribute set that maps aliases (the top level attribute names in
          this option) to command strings or directly to build outputs.
        '';
      };

      shellGlobalAliases = mkOption {
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            UUID = "$(uuidgen | tr -d \\n)";
            G = "| grep";
          }
        '';
        description = ''
          Similar to <xref linkend="opt-programs.zsh.shellAliases"/>,
          but are substituted anywhere on a line.
        '';
      };

      dirHashes = mkOption {
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            docs  = "$HOME/Documents";
            vids  = "$HOME/Videos";
            dl    = "$HOME/Downloads";
          }
        '';
        description = ''
          An attribute set that adds to named directory hash table.
        '';
      };

      completions = {
        enable = mkEnableOption ''
          Enable zsh completion. Don't forget to add
          <programlisting language="nix">
            environment.pathsToLink = [ "/share/zsh" ];
          </programlisting>
          to your system configuration to get completion for system packages (e.g. systemd).
          '' // { default = true; };

        package = mkPackageOption pkgs "zsh-completions" { };

        initCmd = mkOption {
          type = types.lines;
          default = "autoload -U compinit && compinit";
          description = ''
            Initialization commands to run when completion is enabled.
          '';
        };
      };


      autosuggestions = {
        enable = mkEnableOption "Zsh Autosuggestions";

        package = mkPackageOption pkgs "zsh-autosuggestions" { };
      };

      syntaxHighlighting = {
        enable = mkEnableOption "Zsh syntax highlighting";
        package = mkPackageOption pkgs "zsh-syntax-highlighting";
      };

      historySubstringSearch = mkOption {
        type = historySubstringSearchModule;
        default = { };
        description = ''
          Options related to zsh-history-substring-search.
        '';
      };

      history = mkOption {
        type = historyModule;
        default = { };
        description = ''
          Options related to commands history configuration.
        '';
      };

      defaultKeymap = mkOption {
        type = types.nullOr (types.enum (attrNames bindkeyCommands));
        default = null;
        example = "emacs";
        description = ''
          The default base keymap to use.
        '';
      };

      sessionVariables = mkOption {
        type = types.attrs;
        default = { };
        example = { MAILCHECK = 30; };
        description = ''
          Environment variables that will be set for zsh session.
        '';
      };

      initExtraBeforeCompInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra commands that should be added to <filename>.zshrc</filename> before compinit.
        '';
      };

      initExtra = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra commands that should be added to <filename>.zshrc</filename>.
        '';
      };

      initExtraFirst = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Commands that should be added to top of <filename>.zshrc</filename>.
        '';
      };

      envExtra = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra commands that should be added to <filename>.zshenv</filename>.
        '';
      };

      profileExtra = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra commands that should be added to <filename>.zprofile</filename>.
        '';
      };

      loginExtra = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra commands that should be added to <filename>.zlogin</filename>.
        '';
      };

      logoutExtra = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra commands that should be added to <filename>.zlogout</filename>.
        '';
      };

      plugins = mkOption {
        type = types.listOf pluginModule;
        default = [ ];
        example = literalExpression ''
          [
            {
              # will source zsh-autosuggestions.plugin.zsh
              name = "zsh-autosuggestions";
              src = pkgs.fetchFromGitHub {
                owner = "zsh-users";
                repo = "zsh-autosuggestions";
                rev = "v0.4.0";
                sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
              };
            }
            {
              name = "enhancd";
              file = "init.sh";
              src = pkgs.fetchFromGitHub {
                owner = "b4b4r07";
                repo = "enhancd";
                rev = "v2.2.1";
                sha256 = "0iqa9j09fwm6nj5rpip87x3hnvbbz9w9ajgm6wkrd5fls8fn8i5g";
              };
            }
          ]
        '';
        description = ''
          Plugins to source in <filename>.zshrc</filename>.
        '';
      };

      oh-my-zsh = mkOption {
        type = ohMyZshModule;
        default = { };
        description = ''
          Options to configure oh-my-zsh.
        '';
      };

      localVariables = mkOption {
        type = types.attrs;
        default = { };
        example = { POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=["dir" "vcs"]; };
        description = ''
          Extra local variables defined at the top of <filename>.zshrc</filename>.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.profileExtra != "") {
      home.file."${relToDotDir ".zprofile"}".text = cfg.profileExtra;
    })

    (mkIf (cfg.loginExtra != "") {
      home.file."${relToDotDir ".zlogin"}".text = cfg.loginExtra;
    })

    (mkIf (cfg.logoutExtra != "") {
      home.file."${relToDotDir ".zlogout"}".text = cfg.logoutExtra;
    })

    (mkIf (cfg.dotDir != null) {
      # When dotDir is set, only use ~/.zshenv to source ZDOTDIR/.zshenv,
      # This is so that if ZDOTDIR happens to be
      # already set correctly (by e.g. spawning a zsh inside a zsh), all env
      # vars still get exported
      home.file.".zshenv".text = ''
        source ${zdotdir}/.zshenv
      '';
    })

    {
      home.packages = [ cfg.package ]
        ++ optional cfg.completions.enable cfg.completions.package
        ++ optional cfg.oh-my-zsh.enable cfg.oh-my-zsh.package;

      home.file."${relToDotDir ".zshenv"}".text = ''
        # Environment variables
        . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"

        # Only source this once
        if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]; then
          export __HM_ZSH_SESS_VARS_SOURCED=1
          ${config.lib.zsh.exportAll cfg.sessionVariables}
        fi

        ${optionalString cfg.oh-my-zsh.enable ''
          ZSH="${cfg.oh-my-zsh.package}/share/oh-my-zsh";
          ZSH_CACHE_DIR="${config.xdg.cacheHome or "$XDG_CACHE_HOME"}/oh-my-zsh";
        ''}

        ${optionalString (cfg.dotDir != null) "ZDOTDIR=${zdotdir}"}

        ${cfg.envExtra}
      '';

      home.file."${relToDotDir ".zshrc"}".text =
        let
          mkSetOpt = arg: if arg then "setopt" else "unsetopt";
        in
        ''
        # Generated by home-manager

        ${cfg.initExtraFirst}

        typeset -U path cdpath fpath manpath

        ${optionalString (cfg.cdpath != [ ]) "cdpath+=(${concatStringsSep " " cfg.cdpath})"}

        for profile in ''${(z)NIX_PROFILES}; do
          fpath+=(
            $profile/share/zsh/site-functions
            $profile/share/zsh/$ZSH_VERSION/functions
            $profile/share/zsh/vendor-completions
          )
        done

        HELPDIR="${cfg.package}/share/zsh/$ZSH_VERSION/help"

        ${optionalString (cfg.defaultKeymap != null) ''
          # Use ${cfg.defaultKeymap} keymap as the default.
          ${getAttr cfg.defaultKeymap bindkeyCommands}
        ''}

        ${config.lib.zsh.defineAll cfg.localVariables}

        ${cfg.initExtraBeforeCompInit}

        ${concatMapStrings (plugin: ''
          path+="$HOME/${pluginsDir}/${plugin.name}"
          fpath+="$HOME/${pluginsDir}/${plugin.name}"
        '') cfg.plugins}

        # Oh-My-Zsh/Prezto calls compinit during initialization,
        # calling it twice causes slight start up slowdown
        # as all $fpath entries will be traversed again.
        ${optionalString (cfg.completions.enable && !cfg.oh-my-zsh.enable && !cfg.prezto.enable)
          cfg.completions.initCmd
        }

        ${optionalString cfg.autosuggestions.enable
          "source ${cfg.autosuggestions.package}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        }

        ${optionalString cfg.oh-my-zsh.enable ''
            # oh-my-zsh extra settings for plugins
            ${cfg.oh-my-zsh.extraConfig}

            # oh-my-zsh configuration generated by home-manager
            ${optionalString (cfg.oh-my-zsh.plugins != [ ])
              "plugins=(${concatStringsSep " " cfg.oh-my-zsh.plugins})"
            }
            ${optionalString (cfg.oh-my-zsh.custom != "")
              "ZSH_CUSTOM=\"${cfg.oh-my-zsh.custom}\""
            }
            ${optionalString (cfg.oh-my-zsh.theme != "")
              "ZSH_THEME=\"${cfg.oh-my-zsh.theme}\""
            }
            source $ZSH/oh-my-zsh.sh
        ''}

        ${optionalString cfg.prezto.enable
            (builtins.readFile "${cfg.prezto.package}/share/zsh-prezto/runcoms/zshrc")}

        ${concatMapStrings (plugin: ''
          if [[ -f "$HOME/${pluginsDir}/${plugin.name}/${plugin.file}" ]]; then
            source "$HOME/${pluginsDir}/${plugin.name}/${plugin.file}"
          fi
        '') cfg.plugins}

        # History options should be set in .zshrc and after oh-my-zsh sourcing.
        # See https://github.com/nix-community/home-manager/issues/177.
        HISTSIZE="${toString cfg.history.size}"
        SAVEHIST="${toString cfg.history.save}"

        ${optionalString (cfg.history.ignorePatterns != [ ]) "HISTORY_IGNORE=${escapeShellArg "(${concatStringsSep "|" cfg.history.ignorePatterns})"}"}

        HISTFILE="${optionalString (! versionAtLeast config.home.stateVersion "20.03") "$HOME/"}${cfg.history.path}

        mkdir -p "$(dirname "$HISTFILE")"

        setopt HIST_FCNTL_LOCK
        ${mkSetOpt cfg.history.ignoreDups} HIST_IGNORE_DUPS
        ${mkSetOpt cfg.history.ignoreSpace} HIST_IGNORE_SPACE
        ${mkSetOpt cfg.history.expireDuplicatesFirst} HIST_EXPIRE_DUPS_FIRST
        ${mkSetOpt cfg.history.share} SHARE_HISTORY
        ${mkSetOpt cfg.history.extended} EXTENDED_HISTORY
        ${optionalString (cfg.autocd != null) "${mkSetOpt cfg.autocd} autocd"}

        ${cfg.initExtra}

        # Aliases
        ${concatLines (mapAttrsToList (k: v: "alias ${k}=${escapeShellArg v}") cfg.shellAliases)}

        # Global Aliases
        ${concatLines (mapAttrsToList (k: v: "alias -g ${k}=${escapeShellArg v}") cfg.shellGlobalAliases)}

        # Named Directory Hashes
        ${concatLines (mapAttrsToList (k: v: "hash -d ${k}=\"${v}\"") cfg.dirHashes)}

        ${optionalString cfg.syntaxHighlighting.enable or false
            # Load zsh-syntax-highlighting after all custom widgets have been created
            # https://github.com/zsh-users/zsh-syntax-highlighting#faq
            "source ${cfg.syntaxHighlighting.package}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        }

        ${optionalString cfg.historySubstringSearch.enable or false
          # Load zsh-history-substring-search after zsh-syntax-highlighting
          # https://github.com/zsh-users/zsh-history-substring-search#usage
          ''
            source ${cfg.historySubstringSearch.package}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
            bindkey '${cfg.historySubstringSearch.searchUpKey}' history-substring-search-up
            bindkey '${cfg.historySubstringSearch.searchDownKey}' history-substring-search-down
          ''
        }
      '';
    }

    (mkIf cfg.oh-my-zsh.enable {
      # Make sure we create a cache directory since some plugins expect it to exist
      # See: https://github.com/nix-community/home-manager/issues/761
      home.file."${config.xdg.cacheHome}/oh-my-zsh/.keep".text = "";
    })

    (mkIf (cfg.plugins != [ ]) {
      # Many plugins require compinit to be called
      # but allow the user to opt out.
      programs.zsh.completions.enable = mkDefault true;

      home.file = mapListToAttrs' (plugin: nameValuePair "${pluginsDir}/${plugin.name}" { source = plugin.src; }) cfg.plugins;
    })
  ]);
}

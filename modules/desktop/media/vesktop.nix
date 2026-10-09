{
  exo.mods.media =
    { scheme, ... }:
    {
      forte.vesktop = {
        enable = true;
        settings = {
          appBadge = false;
          arRPC = true;
          checkUpdates = false;
          customTitleBar = false;
          disableMinSize = false;
          minimizeToTray = true;
          tray = true;
          splashTheming = true;
          splashBackground = "${scheme.base00}";
          splashColor = "${scheme.base00}";
          staticTitle = true;
          hardwareAcceleration = true;
          discordBranch = "stable";
        };
        vencord-settings = {
          autoUpdate = false;
          autoUpdateNotification = false;
          useQuickCss = true;
          themeLinks = [ ];
          eagerPatches = false;
          enabledThemes = [ "dark.css" ];
          enableReactDevtools = false;
          frameless = false;
          transparent = false;
          winCtrlQ = false;
          disableMinSize = false;
          winNativeTitleBar = false;

          plugins = {
            ChatInputButtonAPI.enabled = true;
            CommandsAPI.enabled = true;
            DynamicImageModalAPI.enabled = false;
            MemberListDecoratorsAPI.enabled = true;
            MessageAccessoriesAPI.enabled = true;
            MessageDecorationsAPI.enabled = true;
            MessageEventsAPI.enabled = false;
            MessagePopoverAPI.enabled = false;
            MessageUpdaterAPI.enabled = false;
            ServerListAPI.enabled = false;
            UserSettingsAPI.enabled = true;
            AccountPanelServerProfile.enabled = false;
            AlwaysAnimate.enabled = false;
            AlwaysExpandRoles.enabled = false;
            AlwaysTrust.enabled = false;
            AnonymiseFileNames.enabled = false;
            AppleMusicRichPresence.enabled = false;
            "WebRichPresence (arRPC)".enabled = false;
            BetterFolders.enabled = false;
            BetterGifAltText.enabled = false;
            BetterGifPicker.enabled = false;
            BetterNotesBox.enabled = false;
            BetterRoleContext.enabled = false;
            BetterRoleDot = {
              enabled = true;
              bothStyles = false;
              copyRoleColorInProfilePopout = false;
            };
            BetterSessions.enabled = false;
            BetterSettings.enabled = false;
            BetterUploadButton.enabled = false;
            BiggerStreamPreview.enabled = false;
            BlurNSFW.enabled = false;
            CallTimer.enabled = false;
            ClearURLs.enabled = false;
            ClientTheme.enabled = false;
            ColorSighted.enabled = false;
            ConsoleJanitor.enabled = false;
            ConsoleShortcuts.enabled = false;
            CopyEmojiMarkdown.enabled = false;
            CopyFileContents.enabled = false;
            CopyStickerLinks.enabled = false;
            CopyUserURLs.enabled = false;
            CrashHandler.enabled = true;
            CtrlEnterSend.enabled = false;
            CustomCommands.enabled = false;
            CustomIdle.enabled = false;
            CustomRPC.enabled = false;
            Dearrow.enabled = false;
            Decor.enabled = false;
            DisableCallIdle.enabled = false;
            DontRoundMyTimestamps.enabled = false;
            Experiments.enabled = false;
            ExpressionCloner.enabled = false;
            F8Break.enabled = false;
            FakeNitro.enabled = false;
            FakeProfileThemes.enabled = false;
            FavoriteEmojiFirst.enabled = false;
            FavoriteGifSearch.enabled = false;
            FixCodeblockGap.enabled = true;
            FixImagesQuality.enabled = false;
            FixSpotifyEmbeds.enabled = false;
            FixYoutubeEmbeds.enabled = false;
            ForceOwnerCrown.enabled = true;
            FriendInvites.enabled = false;
            FriendsSince.enabled = false;
            FullSearchContext.enabled = false;
            FullUserInChatbox.enabled = false;
            GameActivityToggle.enabled = false;
            GifPaste.enabled = false;
            GreetStickerPicker.enabled = false;
            HideMedia.enabled = false;
            iLoveSpam.enabled = false;
            IgnoreActivities.enabled = false;
            ImageFilename.enabled = false;
            ImageLink.enabled = false;
            ImageZoom = {
              enabled = true;
              saveZoomValues = true;
              invertScroll = true;
              nearestNeighbour = false;
              square = false;
              zoom = 5;
              size = 550;
              zoomSpeed = 0.5;
            };
            ImplicitRelationships.enabled = false;
            IrcColors.enabled = false;
            KeepCurrentChannel.enabled = false;
            LastFMRichPresence.enabled = false;
            LoadingQuotes.enabled = false;
            MemberCount.enabled = false;
            MentionAvatars.enabled = false;
            MessageClickActions.enabled = false;
            MessageLatency.enabled = false;
            MessageLinkEmbeds.enabled = false;
            MessageLogger.enabled = false;
            MoreQuickReactions.enabled = false;
            MutualGroupDMs.enabled = false;
            NewGuildSettings.enabled = false;
            NoBlockedMessages.enabled = false;
            NoDefaultHangStatus.enabled = false;
            NoDevtoolsWarning.enabled = false;
            NoF1.enabled = false;
            NoMaskedUrlPaste.enabled = false;
            NoMosaic.enabled = false;
            NoOnboardingDelay.enabled = false;
            NoPendingCount.enabled = false;
            NoProfileThemes.enabled = false;
            NoReplyMention.enabled = false;
            NoServerEmojis.enabled = false;
            NoTypingAnimation.enabled = false;
            NoUnblockToJump.enabled = false;
            NotificationVolume.enabled = false;
            OnePingPerDM.enabled = false;
            oneko.enabled = false;
            OpenInApp.enabled = false;
            OverrideForumDefaults.enabled = false;
            PauseInvitesForever.enabled = false;
            PermissionFreeWill.enabled = false;
            PermissionsViewer.enabled = false;
            petpet.enabled = false;
            PictureInPicture.enabled = false;
            PinDMs = {
              enabled = true;
              userBasedCategoryList = {
                "613524063809437736" = [ ];
              };
              canCollapseDmSection = false;
              pinOrder = 0;
            };
            PlainFolderIcon.enabled = false;
            PlatformIndicators.enabled = false;
            PreviewMessage.enabled = false;
            QuickMention.enabled = false;
            QuickReply.enabled = false;
            ReactErrorDecoder.enabled = false;
            ReadAllNotificationsButton.enabled = false;
            RelationshipNotifier.enabled = false;
            ReplaceGoogleSearch.enabled = false;
            ReplyTimestamp.enabled = false;
            RevealAllSpoilers.enabled = false;
            ReverseImageSearch.enabled = false;
            ReviewDB.enabled = false;
            RoleColorEverywhere = {
              enabled = true;
              chatMentions = true;
              memberList = true;
              voiceUsers = true;
              reactorsList = true;
              pollResults = true;
              colorChatMessages = false;
            };
            SecretRingToneEnabler.enabled = false;
            Summaries.enabled = false;
            SendTimestamps.enabled = false;
            ServerInfo.enabled = false;
            ServerListIndicators.enabled = false;
            ShikiCodeblocks.enabled = false;
            ShowAllMessageButtons.enabled = false;
            ShowConnections.enabled = false;
            ShowHiddenChannels.enabled = false;
            ShowHiddenThings.enabled = false;
            ShowMeYourName.enabled = false;
            ShowTimeoutDuration.enabled = false;
            SilentMessageToggle.enabled = false;
            SilentTyping = {
              enabled = true;
              isEnabled = true;
              showIcon = false;
            };
            SortFriendRequests.enabled = false;
            SpotifyControls.enabled = false;
            SpotifyCrack.enabled = false;
            SpotifyShareCommands.enabled = false;
            StartupTimings.enabled = false;
            StickerPaste.enabled = false;
            StreamerModeOnStream.enabled = false;
            SuperReactionTweaks.enabled = false;
            TextReplace.enabled = false;
            ThemeAttributes.enabled = false;
            Translate.enabled = false;
            TypingIndicator = {
              enabled = true;
              includeMutedChannels = false;
              includeCurrentChannel = true;
              indicatorMode = 3;
            };
            TypingTweaks = {
              enabled = true;
              alternativeFormatting = true;
              showRoleColors = true;
              showAvatars = true;
            };
            Unindent.enabled = true;
            UnlockedAvatarZoom.enabled = false;
            UnsuppressEmbeds.enabled = false;
            UserMessagesPronouns.enabled = false;
            UserVoiceShow = {
              enabled = true;
              showInUserProfileModal = true;
              showInMemberList = true;
              showInMessages = true;
            };
            USRBG.enabled = false;
            ValidReply.enabled = false;
            ValidUser.enabled = false;
            VoiceChatDoubleClick.enabled = true;
            VcNarrator.enabled = false;
            VencordToolbox.enabled = false;
            ViewIcons.enabled = false;
            ViewRaw.enabled = false;
            VoiceDownload.enabled = false;
            VoiceMessages.enabled = false;
            VolumeBooster.enabled = false;
            WebKeybinds.enabled = true;
            WebScreenShareFixes.enabled = true;
            WhoReacted.enabled = false;
            XSOverlay.enabled = false;
            YoutubeAdblock.enabled = false;
            BadgeAPI.enabled = true;
            NoTrack = {
              enabled = true;
              disableAnalytics = true;
            };
            Settings = {
              enabled = true;
              settingsLocation = "aboveNitro";
            };
            DisableDeepLinks.enabled = true;
            SupportHelper.enabled = true;
            WebContextMenus.enabled = true;
          };

          uiElements = {
            chatBarButtons = { };
            messagePopoverButtons = { };
          };

          notifications = {
            timeout = 5000;
            position = "bottom-right";
            useNative = "not-focused";
            logLimit = 50;
          };

          cloud = {
            authenticated = false;
            url = "";
            settingsSync = false;
            settingsSyncVersion = 1773894758681;
          };
        };
      };
    };
  exo.skeleton =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.forte.vesktop;
      jsonFormat = lib.generators.toJSON { };
      theme-repo = pkgs.fetchgit {
        url = "https://codeberg.org/onelock/system-24-with-custom-pallete.git";
        rev = "6666c1b0700a78ff64a98bf9480bc03a4a74c150";
        hash = "sha256-M+ud0Bg597/ZSTc5bEgQ17cyDHGG26BQGemiMDe5rF4=";
      };
    in
    {
      config = lib.mkIf cfg.enable {
        hj.packages = [ cfg.package ];
        hj.xdg.config.files = {
          "vesktop/settings.json" = {
            generator = jsonFormat;
            value = cfg.settings;
          };
          "vesktop/settings/settings.json" = {
            generator = jsonFormat;
            value = cfg.vencord-settings;
          };
          "vesktop/themes/dark.css".source = "${theme-repo}/system24.theme-dark.css";
        };
        hj.systemd.services = {
          vesktop = {
            enableDefaultPath = false;
            description = "vesktop autostart";
            after = [ "graphical-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${lib.getExe cfg.package}";
            };
          };
        };

        forte.hyprland.lua.window-rules = # lua
          ''
            hl.window_rule({
              name            = "vesktop",
              match           = { class = "vesktop" },
              scrolling_width = 0.5,
              workspace       = "5 silent",
              suppress_event  = "fullscreen maximize activate activatefocus",
              fullscreen_state = "0 3",
            })
          '';
        forte.persist.home.directories = [ ".config/vesktop" ];
      };
      options.forte.vesktop = {
        enable = lib.mkEnableOption "vesktop";
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.vesktop.override { withMiddleClickScroll = true; };
        };
        settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        vencord-settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      };
    };
}

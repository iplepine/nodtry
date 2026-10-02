// Invite / download landing for 둘운완.
// <body data-mode="invite"> reads the code from /i/{CODE} (or ?code=),
// <body data-mode="get"> only sends people to the right store.
(function () {
  "use strict";

  var APP_STORE_URL = "https://apps.apple.com/kr/app/id6761373605";
  var ANDROID_PACKAGE = "com.devho.nodtry.app";
  var PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=" + ANDROID_PACKAGE;
  // The app's own scheme; it routes /i/{CODE} to code entry (lib/routes/app_router.dart).
  var APP_SCHEME = "onmybehalf";
  // Same shape the app accepts: 8 upper-case letters/digits.
  var CODE_PATTERN = /^[A-Z0-9]{8}$/;

  function platform() {
    var ua = navigator.userAgent || "";
    if (/android/i.test(ua)) return "android";
    if (/iPad|iPhone|iPod/.test(ua)) return "ios";
    // iPadOS reports itself as a Mac.
    if (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1) return "ios";
    return "other";
  }

  function readCode() {
    var parts = window.location.pathname.split("/").filter(Boolean);
    var raw = parts[0] === "i" && parts[1] ? parts[1] : "";
    if (!raw) {
      var match = /[?&]code=([^&#]*)/.exec(window.location.search);
      raw = match ? match[1] : "";
    }
    try {
      raw = decodeURIComponent(raw);
    } catch (e) {
      // keep the raw value
    }
    var code = raw.toUpperCase().replace(/[^A-Z0-9]/g, "");
    return CODE_PATTERN.test(code) ? code : null;
  }

  function playStoreUrl(code) {
    // Marks the install with the code for a planned Play Install Referrer
    // read-back. The app does not read it yet: today the invitee pastes the
    // copied code (or opens the link again once the app is installed).
    return code ? PLAY_STORE_URL + "&referrer=" + encodeURIComponent("invite_code=" + code) : PLAY_STORE_URL;
  }

  // Opens the installed app at this invite. On Android an intent: URL falls
  // back to the Play listing when the app is not installed; iOS has no
  // fallback for a custom scheme, so the store button stays the main action.
  function openAppUrl(os, code) {
    var path = "app/i/" + code;
    if (os === "android") {
      return "intent://" + path + "#Intent;scheme=" + APP_SCHEME + ";package=" + ANDROID_PACKAGE +
        ";S.browser_fallback_url=" + encodeURIComponent(playStoreUrl(code)) + ";end";
    }
    if (os === "ios") return APP_SCHEME + "://" + path;
    return null;
  }

  function storeUrlFor(os, code) {
    if (os === "ios") return APP_STORE_URL;
    if (os === "android") return playStoreUrl(code);
    return null;
  }

  function legacyCopy(text) {
    var area = document.createElement("textarea");
    area.value = text;
    area.setAttribute("readonly", "");
    area.style.position = "fixed";
    area.style.top = "-1000px";
    area.style.opacity = "0";
    document.body.appendChild(area);
    area.focus();
    area.select();
    area.setSelectionRange(0, text.length);
    var ok = false;
    try {
      ok = document.execCommand("copy");
    } catch (e) {
      ok = false;
    }
    document.body.removeChild(area);
    return ok;
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).then(
        function () { return true; },
        function () { return legacyCopy(text); }
      );
    }
    return Promise.resolve(legacyCopy(text));
  }

  function init() {
    var mode = document.body.getAttribute("data-mode");
    var os = platform();
    var code = mode === "invite" ? readCode() : null;

    var codeCard = document.getElementById("code-card");
    var codeText = document.getElementById("code");
    var missing = document.getElementById("missing");
    var cta = document.getElementById("cta");
    var status = document.getElementById("status");
    var stores = document.getElementById("stores");
    var appStoreLink = document.getElementById("app-store");
    var playStoreLink = document.getElementById("play-store");
    var openApp = document.getElementById("open-app");

    appStoreLink.href = APP_STORE_URL;
    playStoreLink.href = playStoreUrl(code);

    var appUrl = code ? openAppUrl(os, code) : null;
    if (openApp && appUrl) {
      openApp.href = appUrl;
      openApp.hidden = false;
    }

    if (mode === "invite") {
      if (code) {
        codeText.textContent = code;
        codeCard.hidden = false;
        cta.textContent = "코드 복사하고 앱 받기";
      } else {
        codeCard.hidden = true;
        missing.hidden = false;
        cta.textContent = "앱 받기";
      }
    }

    // On a computer there is no store to jump to: show both links.
    if (os === "other") stores.hidden = false;

    function setStatus(message, ok) {
      status.textContent = message;
      status.className = ok ? "status ok" : "status";
    }

    function goToStore() {
      var url = storeUrlFor(os, code);
      if (url) {
        window.location.href = url;
      } else {
        stores.hidden = false;
        setStatus("휴대폰에서 이 링크를 열면 바로 설치할 수 있어요.", false);
      }
    }

    cta.addEventListener("click", function () {
      if (!code) {
        goToStore();
        return;
      }
      copyText(code).then(function (copied) {
        if (os === "other") {
          stores.hidden = false;
          setStatus(
            (copied ? "코드를 복사했어요! " : "") + "휴대폰에서 이 링크를 열면 바로 설치할 수 있어요.",
            copied
          );
          return;
        }
        if (copied) {
          setStatus("코드를 복사했어요! 앱을 설치하고 초대 코드에 붙여 넣어 주세요.", true);
        } else {
          setStatus("앱을 설치하고 위의 코드를 입력해 주세요.", false);
        }
        // Give people a moment to see that the code was copied.
        window.setTimeout(goToStore, 700);
      });
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();

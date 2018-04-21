window.EasyInstantMessaging = function (opts) {
  var notify;
  var alreadyNotified = [];
  var notificationStorageKey = (window.location.hostname + ".EasyInstantMessenger_NotifiedMessageIDs");
  if ("localStorage" in window) {
    alreadyNotified = JSON.parse(localStorage.getItem(notificationStorageKey)) || [];
    localStorage.removeItem(notificationStorageKey);
  }

  this.id = randomKey(3);

  var defaultOptions = {
    checkMessageUrl: null,
    newChatUrl: null,
    readMessageUrl: null,
    apiKey: null,
    defaultTime: 70 * 1000,
    hyperTime: 15 * 1000,
    useRegularOrder: true,
    soundEnabled: true,
    audioTagId: 'easy_instant_message_audio_notice',
    el: {
      wrapper: '#easy_instant_messages_wrapper',
      toggle: '#easy_instant_messages_toggle'
    }
  };

  var options = $.extend({}, defaultOptions, opts);

  var audioTag = document.getElementById(options.audioTagId);

  this.newMessagesCount = 0;

  this.settings = function(name) {
    return options[name]
  };

  var storeNotifiedMessageId = function(id) {
    alreadyNotified.push(id);
    if ("localStorage" in window) {
      localStorage.setItem(notificationStorageKey, JSON.stringify(alreadyNotified));
    }
  };
  var isAlreadyNotified = function(id) {
    return ((JSON.parse(localStorage.getItem(notificationStorageKey)) || []).indexOf(id) !== -1);
  };

  this.init = function () {
    this.interval = setInterval(this.checkMessages, options.defaultTime, this);
    this.chatWindow = false;
    this.checkMessages();
    this.watchEsc();
  };

  this.openChat = function() {
    this.chatWindow = true;
    $(options.el.wrapper).removeClass("easyim__wrapper--hidden");
    $(options.el.toggle).addClass("active");
  };

  this.closeChat = function() {
    this.chatWindow = false;

    window.clearInterval(this.interval);
    this.interval = window.setInterval(this.checkMessages, options.defaultTime, this);

    $(options.el.wrapper).addClass("easyim__wrapper--hidden");
    $(options.el.toggle).removeClass("active");
    this.displayReceivedMessagesCount();
  };

  this.toggleChat = function(e) {
    if (this.chatWindow) {
      e.stopImmediatePropagation();
      e.preventDefault();

      this.closeChat();

      return false;
    } else {
      this.openChat();
    }
  };

  this.displayReceivedMessagesCount = function() {
    var toggle = $(options.el.toggle);

    if (this.newMessagesCount > 0) {
      if (toggle.hasClass("change-color-event")) {
        toggle.children('span').text(this.newMessagesCount);
      } else {
        toggle.addClass("change-color-event");
        var mark = $("<span/>").attr("class", "sign count").text(this.newMessagesCount);
        toggle.append(mark);
      }

    } else {
      toggle.removeClass("change-color-event");
      toggle.contents().remove('.sign');
    }
  };

  this.receiveMessage = function (message) {
    this.setupNotifications();
    // conversation opened with sender and message is not yet in the container
    var conversationWithSender = $("#easy_instant_messages_conversation_with_" + message.sender_id);

    if (this.chatWindow && conversationWithSender.size() > 0) {
      if (!document.getElementById($(message.html).attr('id'))) {
        this.pushMessageToChat(message.html);
      }
      this.readMessage(message);
      this.newMessagesCount -= 1;

    } else {
      this.displayReceivedMessagesCount();
    }

    this.showNotification(message.sender, message);
  };

  this.readMessage = function(message) {
    $.ajax({
      url: options.readMessageUrl,
      data: {id: message.id, key: options.apiKey},
      noLoader: true,
      dataType: 'json',
      type: 'PUT'
    });
  };

  this.checkMessages = function (instance) {
    var _this = instance || this;
    $.ajax({
      url: options.checkMessageUrl,
      data: {key: options.apiKey},
      noLoader: true,
      dataType: 'json',
      success: function (response) {
        var data = response['easy_instant_messages'];

        _this.newMessagesCount = data.length;

        if (_this.newMessagesCount <= 0) {
          _this.displayReceivedMessagesCount();
        } else {
          $.each(data, function (index, message) {
            _this.receiveMessage(message)
          });
        }
      }
    });
  };
  this.showNotification = function (title, message) {
    if (isAlreadyNotified(message.id))
      return;

    if (notify) {
      this.notification = new Notification(title, {
        body: message.text,
        lang: message.language,
        tag: message.tag,
        icon: message.icon
      });

      this.notification.onclick = function () {
        window.focus();
        window.EasyInstantMessenger.openChat();

        $.ajax({
          url: window.urlPrefix +'/easy_instant_messages/' + message.sender_id + '/conversation',
          dataType: 'script',
          type: 'GET'
        });
      };

      if (audioTag && typeof(audioTag.play) === 'function')
        audioTag.play();
    }

    storeNotifiedMessageId(message.id);
  };

  this.titleNotification = function() {
    document.title = document.title.replace(/\(\d+\)\s/, "");
    if (this.newMessagesCount > 0)
      document.title = "(" + this.newMessagesCount + ") " + document.title;
  };
  this.setupNotifications = function () {
    if ("Notification" in window) {
      notify = Notification.permission == "granted";
      Notification.requestPermission(function (status) {
        // This allows to use Notification.permission with Chrome/Safari
        if (Notification.permission !== status) {
          Notification.permission = status;
          notify = Notification.permission == "granted";
        }
      });
    }

  };

  this.newChat = function (id, clickEl) {
    if (clickEl && clickEl.className.indexOf("unread") !== -1) {
      clickEl.remove();
      this.newMessagesCount = (this.newMessagesCount - 1);
    }
    $.get(options.newChatUrl, {user_id: id});
  };

  this.observeKeyUpInChat = function (event) {
    if (event.keyCode == "13") {
      $(event.target.form).submit();
    } else if (event.keyCode == "27") {
      this.closeChat();
    }
  };

  this.pushMessageToChat = function (message_html) {
    var conversationMessages = $("#easy_instant_messages_conversation_messages");

    var newMessage = $(message_html);

    conversationMessages.append(newMessage);

    var appendedMessage = $('#' + newMessage.attr('id'));

    if (!appendedMessage.prev().hasClass("mine")) {
      appendedMessage.prev().find('.easyim__message__avatar').addClass("easyim__message__avatar--hidden");
    }

    if (options.useRegularOrder) {
      this.scrollToBottomOfChatWindow();
    }
  };
  this.scrollToBottomOfChatWindow = function () {
    var el = document.getElementById("easy_instant_messages_conversation_messages");

    if (el) {
      $(el).scrollTop(el.scrollHeight);
    }
  };
  this.supressNotificationFor = function(message) {
    localStorage.getItem()
  };

  this.watchEsc = function() {
    var _this = this;
    $(document).keyup(function(e) {
      if (e.keyCode === 27) {
        _this.closeChat();
      }
    });
  };

  this.init(); // run setup

  this.watchSubmitInput = function() {
    var messageForm = $("#new_easy_instant_message");

    messageForm.find("#easy_instant_message_content").keypress(function(e) {
      var code = e.keyCode ? e.keyCode : e.which;
      if (code == 13 || code == 10) {
        e.preventDefault(); // don't make new line
        messageForm.submit();
      }
    });
  };

  this.focusSubmitInput = function() {
    $("#easy_instant_message_content").focus();
  };

  this.setDefaultInterval = function() {
    window.clearInterval(this.interval);
    this.interval = setInterval(this.checkMessages, options.defaultTime, this);
  }

  this.setHyperInterval = function() {
    window.clearInterval(this.interval);
    this.interval = setInterval(this.checkMessages, options.hyperTime, this);
  }
};

$(document).ready(function() {
  $("#easy_instant_messages_toggle").click(function(e) {
    EasyInstantMessenger.toggleChat(e);
  });

  $("#easy_instant_messages_top_close").click(function(e) {
    EasyInstantMessenger.closeChat();
  });
});

// Applied globally on all textareas with the "autoExpand" class
$(document)
    .one('focus.autoExpand', 'textarea.autoExpand', function(){
      var savedValue = this.value;
      this.value = '';
      this.baseScrollHeight = this.scrollHeight;
      this.value = savedValue;
    })
    .on('input.autoExpand', 'textarea.autoExpand', function(){
      var minRows = 1;//this.getAttribute('data-min-rows')|0, rows;
      this.rows = minRows;
      rows = Math.ceil((this.scrollHeight - this.baseScrollHeight) / 14);
      this.rows = minRows + rows;
    });

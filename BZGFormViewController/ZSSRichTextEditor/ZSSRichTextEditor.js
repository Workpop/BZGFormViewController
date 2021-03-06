var NativeBridge = {
    callbacksCount: 1,
    callbacks: {},

    // Automatically called by native layer when a result is available
    resultForCallback: function resultForCallback(callbackId, resultArray) {
        try {
            var callback = NativeBridge.callbacks[callbackId];
            if (!callback) return;

            callback.apply(null, resultArray);
        } catch (e) {
            alert(e)
        }
    },

    // Use this in javascript to request native objective-c code
    // functionName : string (I think the name is explicit :p)
    // args : array of arguments
    // callback : function with n-arguments that is going to be called when the native code returned
    call: function call(functionName, args, callback) {

        var hasCallback = callback && typeof callback == "function";
        var callbackId = hasCallback ? NativeBridge.callbacksCount++ : 0;

        if (hasCallback)
            NativeBridge.callbacks[callbackId] = callback;

        var iframe = document.createElement("IFRAME");
        iframe.setAttribute("src", "js-frame:" + functionName + ":" + callbackId + ":" + encodeURIComponent(JSON.stringify(args)));
        document.documentElement.appendChild(iframe);
        iframe.parentNode.removeChild(iframe);
        iframe = null;
    }
};

console = new Object();
console.log = function(log) {
    var iframe = document.createElement("IFRAME");
    iframe.setAttribute("src", "ios-log:#iOS#" + log);
    document.documentElement.appendChild(iframe);
    iframe.parentNode.removeChild(iframe);
    iframe = null;
};
console.debug = console.log;
console.info = console.log;
console.warn = console.log;
console.error = console.log;


/*!
 *
 * ZSSRichTextEditor v0.5.2
 * http://www.zedsaid.com
 *
 * Copyright 2014 Zed Said Studio LLC
 *
 */

var zss_editor = {};

// If we are using iOS or desktop
zss_editor.isUsingiOS = true;

// The current selection
zss_editor.currentSelection;

// The current editing image
zss_editor.currentEditingImage;

// The current editing link
zss_editor.currentEditingLink;

// The objects that are enabled
zss_editor.enabledItems = {};

zss_editor.range;

zss_editor.savedRange;


/**
 * The initializer function that must be called onLoad
 */
zss_editor.init = function() {

        var editor = $('#zss_editor_content');

        editor.on('click', function(e) {
            var c = zss_editor.getCaretYPosition();
            var relativeCaretYPosition = zss_editor.getRelativeCaretYPosition();
            var e = document.getElementById('zss_editor_content');
            var contentHeight = e.scrollHeight;
            NativeBridge.call("editorDidBeginEditing", [contentHeight, c, relativeCaretYPosition]);
        });

        editor.keyup(function(e) {

            if (e.keyCode == "13") {
                     
                // if not a list tag add a new paragraph
                if (!whichTag("li") && !whichTag("ul") && !whichTag("ol")) {
                    document.execCommand('formatBlock', false, "p");
                }

                function whichTag(tagName) {
                    var sel, containerNode;
                    tagName = tagName.toUpperCase();
                    if (window.getSelection) {
                        sel = window.getSelection();
                        if (sel.rangeCount > 0) {
                            containerNode = sel.getRangeAt(0).commonAncestorContainer;
                        }
                    } else if ((sel = document.selection) && sel.type != "Control") {
                        containerNode = sel.createRange().parentElement();
                    }
                    while (containerNode) {
//                        console.log(containerNode.tagName);
                        if (containerNode.nodeType == 1 && containerNode.tagName == tagName) {
                            return true;
                        }
                        containerNode = containerNode.parentNode;
                    }
                    return false;
                }

            }

            // save carret selection
            zss_editor.saveSelection();

            // dispatch content height change
            zss_editor.dispatchContentHeightChanged();
        });

        editor.onselectionchange = function() {
            zss_editor.saveSelection();
            NativeBridge.call("updateCarretPosition", [zss_editor.getCaretYPosition(), zss_editor.getRelativeCaretYPosition()]);
        };

        editor.focusout(function() {
            NativeBridge.call("editorDidEndEditing", []);
        });

        // when user pastes
        editor.bind('paste', function(e) {
            handlepaste(this, e);
        });

    } //end


zss_editor.getCurrentContainerNode = function() {
    var containerNode, node;
    if (window.getSelection) {
        node = window.getSelection().anchorNode;
        containerNode = node.nodeType === 3 ? node.parentNode : node;
    }
    return containerNode;
}


zss_editor.strip_tags = function(str, allowed_tags) {

    var key = '',
        allowed = false;
    var matches = [];
    var allowed_array = [];
    var allowed_tag = '';
    var i = 0;
    var k = '';
    var html = '';
    var replacer = function(search, replace, str) {
        return str.split(search).join(replace);
    };
    // Build allowes tags associative array
    if (allowed_tags) {
        allowed_array = allowed_tags.match(/([a-zA-Z0-9]+)/gi);
    }
    str += '';

    // Match tags
    matches = str.match(/(<\/?[\S][^>]*>)/gi);
    // Go through all HTML tags
    for (key in matches) {
        if (isNaN(key)) {
            // IE7 Hack
            continue;
        }

        // Save HTML tag
        html = matches[key].toString();
        // Is tag not in allowed list? Remove from str!
        allowed = false;

        // Go through all allowed tags
        for (k in allowed_array) { // Init
            allowed_tag = allowed_array[k];
            i = -1;

            if (i != 0) {
                i = html.toLowerCase().indexOf('<' + allowed_tag + '>');
            }
            if (i != 0) {
                i = html.toLowerCase().indexOf('<' + allowed_tag + ' ');
            }
            if (i != 0) {
                i = html.toLowerCase().indexOf('</' + allowed_tag);
            }

            // Determine
            if (i == 0) {
                allowed = true;
                break;
            }
        }
        if (!allowed) {
            str = replacer(html, "", str); // Custom replace. No regexing
        }
    }
    return str;
}



// This will show up in the XCode console as we are able to push this into an NSLog.
zss_editor.debug = function(msg) {
    window.location = 'debug://' + msg;
}

zss_editor.setPlaceholder = function(placeholder) {

    var editor = $('#zss_editor_content');

    //set placeHolder
    if (editor.text().length == 1) {
        editor.text(placeholder);
        editor.css("color", "gray");
    }
    //set focus
    editor.focus(function() {
        if ($(this).text() == placeholder) {
            $(this).text("");
            $(this).css("color", "black");
        }
    }).focusout(function() {
        if (!$(this).text().length) {
            $(this).text(placeholder);
            $(this).css("color", "gray");
        }
    });
}

zss_editor.getCaretYPosition = function() {
    var sel = window.getSelection();
    // Next line is comented to prevent deselecting selection. It looks like work but if there are any issues will appear then uconmment it as well as code above.
    //sel.collapseToStart();
    var range = sel.getRangeAt(0);
    var span = document.createElement('span'); // something happening here preventing selection of elements
    range.insertNode(span);
    var topPosition = span.offsetTop;
    span.parentNode.removeChild(span);

    return topPosition;
}

zss_editor.getRelativeCaretYPosition = function() {
    var y = 0;
    var sel = window.getSelection();
    if (sel.rangeCount) {
        var range = sel.getRangeAt(0);
        var needsWorkAround = (range.startOffset == 0)
        /* Removing fixes bug when node name other than 'div' */
        // && range.startContainer.nodeName.toLowerCase() == 'div');
        if (needsWorkAround) {
            y = range.startContainer.offsetTop - window.pageYOffset;
        } else {
            if (range.getClientRects) {
                var rects=range.getClientRects();
                if (rects.length > 0) {
                    y = rects[0].top;
                }
            }
        }
    }
    return y;
}

zss_editor.backuprange = function() {
    var selection = window.getSelection();
    var range = selection.getRangeAt(0);
    zss_editor.currentSelection = {
        "startContainer": range.startContainer,
        "startOffset": range.startOffset,
        "endContainer": range.endContainer,
        "endOffset": range.endOffset
    };
}

zss_editor.restorerange = function() {
    var selection = window.getSelection();
    selection.removeAllRanges();
    var range = document.createRange();
    range.setStart(zss_editor.currentSelection.startContainer, zss_editor.currentSelection.startOffset);
    range.setEnd(zss_editor.currentSelection.endContainer, zss_editor.currentSelection.endOffset);
    selection.addRange(range);
}

zss_editor.getSelectedNode = function() {
    var node, selection;
    if (window.getSelection) {
        selection = getSelection();
        node = selection.anchorNode;
    }
    if (!node && document.selection) {
        selection = document.selection
        var range = selection.getRangeAt ? selection.getRangeAt(0) : selection.createRange();
        node = range.commonAncestorContainer ? range.commonAncestorContainer :
            range.parentElement ? range.parentElement() : range.item(0);
    }
    if (node) {
        return (node.nodeName == "#text" ? node.parentNode : node);
    }
};

zss_editor.setBold = function() {
    document.execCommand('bold', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setItalic = function() {
    document.execCommand('italic', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setSubscript = function() {
    document.execCommand('subscript', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setSuperscript = function() {
    document.execCommand('superscript', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setStrikeThrough = function() {
    document.execCommand('strikeThrough', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setUnderline = function() {
    document.execCommand('underline', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setBlockquote = function() {
    document.execCommand('formatBlock', false, '<blockquote>');
    zss_editor.enabledEditingItems();
}

zss_editor.removeFormating = function() {
    document.execCommand('removeFormat', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setHorizontalRule = function() {
    document.execCommand('insertHorizontalRule', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setHeading = function(heading) {
    var current_selection = $(zss_editor.getSelectedNode());
    var t = current_selection.prop("tagName").toLowerCase();
    var is_heading = (t == 'h1' || t == 'h2' || t == 'h3' || t == 'h4' || t == 'h5' || t == 'h6');
    if (is_heading && heading == t) {
        var c = current_selection.html();
        current_selection.replaceWith(c);
    } else {
        document.execCommand('formatBlock', false, '<' + heading + '>');
    }

    zss_editor.enabledEditingItems();
}

zss_editor.setParagraph = function() {
    var current_selection = $(zss_editor.getSelectedNode());
    var t = current_selection.prop("tagName").toLowerCase();

    console.log(t);

    var is_paragraph = (t == 'p');
    if (is_paragraph) {
        var c = current_selection.html();
        current_selection.replaceWith(c);
    } else {
        document.execCommand('formatBlock', false, '<p>');
    }

    zss_editor.enabledEditingItems();
}

// Need way to remove formatBlock
console.log('WARNING: We need a way to remove formatBlock items');

zss_editor.undo = function() {
    document.execCommand('undo', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.redo = function() {
    document.execCommand('redo', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setOrderedList = function() {
    document.execCommand('insertOrderedList', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setUnorderedList = function() {
    document.execCommand('insertUnorderedList', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setJustifyCenter = function() {
    document.execCommand('justifyCenter', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setJustifyFull = function() {
    document.execCommand('justifyFull', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setJustifyLeft = function() {
    document.execCommand('justifyLeft', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setJustifyRight = function() {
    document.execCommand('justifyRight', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setIndent = function() {
    document.execCommand('indent', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setOutdent = function() {
    document.execCommand('outdent', false, null);
    zss_editor.enabledEditingItems();
}

zss_editor.setTextColor = function(color) {
    zss_editor.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('foreColor', false, color);
    document.execCommand("styleWithCSS", null, false);
    zss_editor.enabledEditingItems();
    // document.execCommand("removeFormat", false, "foreColor"); // Removes just foreColor
}

zss_editor.setBackgroundColor = function(color) {
    zss_editor.restorerange();
    document.execCommand("styleWithCSS", null, true);
    document.execCommand('hiliteColor', false, color);
    document.execCommand("styleWithCSS", null, false);
    zss_editor.enabledEditingItems();
}

// Needs addClass method

zss_editor.insertLink = function(url, title) {

    zss_editor.restorerange();
    var sel = document.getSelection();
    console.log(sel);
    if (sel.toString().length != 0) {
        if (sel.rangeCount) {

            var el = document.createElement("a");
            el.setAttribute("href", url);
            el.setAttribute("title", title);

            var range = sel.getRangeAt(0).cloneRange();
            range.surroundContents(el);
            sel.removeAllRanges();
            sel.addRange(range);
        }
    }
    zss_editor.enabledEditingItems();
}

zss_editor.updateLink = function(url, title) {

        zss_editor.restorerange();

        if (zss_editor.currentEditingLink) {
            var c = zss_editor.currentEditingLink;
            c.attr('href', url);
            c.attr('title', title);
        }
        zss_editor.enabledEditingItems();

    } //end

zss_editor.updateImage = function(url, alt) {

        zss_editor.restorerange();

        if (zss_editor.currentEditingImage) {
            var c = zss_editor.currentEditingImage;
            c.attr('src', url);
            c.attr('alt', alt);
        }
        zss_editor.enabledEditingItems();

    } //end

zss_editor.unlink = function() {

    if (zss_editor.currentEditingLink) {
        var c = zss_editor.currentEditingLink;
        c.contents().unwrap();
    }
    zss_editor.enabledEditingItems();
}

zss_editor.quickLink = function() {

    var sel = document.getSelection();
    var link_url = "";
    var test = new String(sel);
    var mailregexp = new RegExp("^(.+)(\@)(.+)$", "gi");
    if (test.search(mailregexp) == -1) {
        checkhttplink = new RegExp("^http\:\/\/", "gi");
        if (test.search(checkhttplink) == -1) {
            checkanchorlink = new RegExp("^\#", "gi");
            if (test.search(checkanchorlink) == -1) {
                link_url = "http://" + sel;
            } else {
                link_url = sel;
            }
        } else {
            link_url = sel;
        }
    } else {
        checkmaillink = new RegExp("^mailto\:", "gi");
        if (test.search(checkmaillink) == -1) {
            link_url = "mailto:" + sel;
        } else {
            link_url = sel;
        }
    }

    var html_code = '<a href="' + link_url + '">' + sel + '</a>';
    zss_editor.insertHTML(html_code);

}

zss_editor.prepareInsert = function() {
    zss_editor.backuprange();
}

zss_editor.insertImage = function(url, alt) {
    zss_editor.restorerange();
    var html = '<img src="' + url + '" alt="' + alt + '" />';
    zss_editor.insertHTML(html);
    zss_editor.enabledEditingItems();
}

zss_editor.setHTML = function(html) {

    // strip anything out other than the following characters
    html = zss_editor.strip_tags(html, "<p><b><ul><ol><li><strong><i><em>");

    // set contents
    var editor = $('#zss_editor_content');
    editor.html(html);

    // wrap any unwrapped text elements in p tags
    var textnodes = zss_editor.getTextNodesIn(editor[0]);
    for (var i = 0; i < textnodes.length; i++) {
        if ($(textnodes[i]).parent().is('#zss_editor_content')) {
            $(textnodes[i]).wrap("<p>");
        }
    }
    
    // notify new height
    var e = document.getElementById('zss_editor_content');

    NativeBridge.call("updateContentHeight", [e.scrollHeight]);
}

zss_editor.insertHTML = function(html) {
    document.execCommand('insertHTML', false, html);
    zss_editor.enabledEditingItems();
}

zss_editor.getHTML = function() {

    // wrap any unwrapped text elements in p tags
    var textnodes = zss_editor.getTextNodesIn($("#zss_editor_content")[0]);
    for (var i = 0; i < textnodes.length; i++) {
        if ($(textnodes[i]).parent().is("#zss_editor_content")) {
            $(textnodes[i]).wrap("<p>");
        }
    }

    // remove any empty tags
    $("#zss_editor_content").find("*").filter(function() {
        return $(this).text().trim().length == 0
    }).remove();


    // Get the contents
    var h = document.getElementById("zss_editor_content").innerHTML;

    return h;
}

zss_editor.getTextNodesIn = function(node, includeWhitespaceNodes) {
    var textNodes = [],
        whitespace = /^\s*$/;

    function getTextNodes(node) {
        if (node.nodeType == 3) {
            if (includeWhitespaceNodes || !whitespace.test(node.nodeValue)) {
                textNodes.push(node);
            }
        } else {
            for (var i = 0, len = node.childNodes.length; i < len; ++i) {
                getTextNodes(node.childNodes[i]);
            }
        }
    }

    getTextNodes(node);
    return textNodes;
}

zss_editor.getText = function() {
    return $('#zss_editor_content').text();
}

zss_editor.isCommandEnabled = function(commandName) {
    return document.queryCommandState(commandName);
}

zss_editor.enabledEditingItems = function(e) {

    console.log('enabledEditingItems');
    var items = [];
    if (zss_editor.isCommandEnabled('bold')) {
        items.push('bold');
    }
    if (zss_editor.isCommandEnabled('italic')) {
        items.push('italic');
    }
    if (zss_editor.isCommandEnabled('subscript')) {
        items.push('subscript');
    }
    if (zss_editor.isCommandEnabled('superscript')) {
        items.push('superscript');
    }
    if (zss_editor.isCommandEnabled('strikeThrough')) {
        items.push('strikeThrough');
    }
    if (zss_editor.isCommandEnabled('underline')) {
        items.push('underline');
    }
    if (zss_editor.isCommandEnabled('insertOrderedList')) {
        items.push('orderedList');
    }
    if (zss_editor.isCommandEnabled('insertUnorderedList')) {
        items.push('unorderedList');
    }
    if (zss_editor.isCommandEnabled('justifyCenter')) {
        items.push('justifyCenter');
    }
    if (zss_editor.isCommandEnabled('justifyFull')) {
        items.push('justifyFull');
    }
    if (zss_editor.isCommandEnabled('justifyLeft')) {
        items.push('justifyLeft');
    }
    if (zss_editor.isCommandEnabled('justifyRight')) {
        items.push('justifyRight');
    }
    if (zss_editor.isCommandEnabled('insertHorizontalRule')) {
        items.push('horizontalRule');
    }
    var formatBlock = document.queryCommandValue('formatBlock');
    if (formatBlock.length > 0) {
        items.push(formatBlock);
    }
    // Images
    $('img').bind('touchstart', function(e) {
        $('img').removeClass('zs_active');
        $(this).addClass('zs_active');
    });

    // Use jQuery to figure out those that are not supported
    if (typeof(e) != "undefined") {

        // The target element
        var t = $(e.target);
        var nodeName = e.target.nodeName.toLowerCase();

        // Background Color
        var bgColor = t.css('backgroundColor');
        if (bgColor.length != 0 && bgColor != 'rgba(0, 0, 0, 0)' && bgColor != 'rgb(0, 0, 0)' && bgColor != 'transparent') {
            items.push('backgroundColor');
        }
        // Text Color
        var textColor = t.css('color');
        if (textColor.length != 0 && textColor != 'rgba(0, 0, 0, 0)' && textColor != 'rgb(0, 0, 0)' && textColor != 'transparent') {
            items.push('textColor');
        }
        // Link
        if (nodeName == 'a') {
            zss_editor.currentEditingLink = t;
            var title = t.attr('title');
            items.push('link:' + t.attr('href'));
            if (t.attr('title') !== undefined) {
                items.push('link-title:' + t.attr('title'));
            }

        } else {
            zss_editor.currentEditingLink = null;
        }
        // Blockquote
        if (nodeName == 'blockquote') {
            items.push('indent');
        }
        // Image
        if (nodeName == 'img') {
            zss_editor.currentEditingImage = t;
            items.push('image:' + t.attr('src'));
            if (t.attr('alt') !== undefined) {
                items.push('image-alt:' + t.attr('alt'));
            }

        } else {
            zss_editor.currentEditingImage = null;
        }

    }

    if (items.length > 0) {
        if (zss_editor.isUsingiOS) {
            window.location = "callback://0/" + items.join(',');
        } else {
            console.log("callback://" + items.join(','));
        }
    } else {
        if (zss_editor.isUsingiOS) {
            window.location = "zss-callback/";
        } else {
            console.log("callback://");
        }
    }
}

zss_editor.focusWysiwyg = function() {
    zss_editor.restoreSelection();
}


zss_editor.saveSelection = function(updateCarret) {

    if (window.getSelection) //non IE Browsers
    {
        zss_editor.savedRange = window.getSelection().getRangeAt(0);
    } else if (document.selection) //IE
    {
        zss_editor.savedRange = document.selection.createRange();
    }
}

zss_editor.restoreSelection = function() {

    var editor = $('#zss_editor_content');
    editor.focus();

    if (zss_editor.savedRange != null) {
        if (window.getSelection) //non IE and there is already a selection
        {
            var s = window.getSelection();
            if (s.rangeCount > 0)
                s.removeAllRanges();
            s.addRange(zss_editor.savedRange);
        }
    }
}

// obj-c dispatching

zss_editor.dispatchContentHeightChanged = function() {

    var c = zss_editor.getCaretYPosition();
    var relativeCaretYPosition = zss_editor.getRelativeCaretYPosition();
    var e = document.getElementById('zss_editor_content');
    var contentHeight = e.scrollHeight;
    NativeBridge.call("contentHeightDidChange", [contentHeight, c, relativeCaretYPosition]);
}

// pasting

function handlepaste(elem, e) {
    var savedcontent = elem.innerHTML;
    if (e && e.clipboardData && e.clipboardData.getData) { // Webkit - get data from clipboard, put into editdiv, cleanup, then cancel event
        if (/text\/html/.test(e.clipboardData.types)) {
            elem.innerHTML = e.clipboardData.getData('text/html');
        } else if (/text\/plain/.test(e.clipboardData.types)) {
            elem.innerHTML = e.clipboardData.getData('text/plain');
        } else {
            elem.innerHTML = "";
        }
        waitforpastedata(elem, savedcontent);
        if (e.preventDefault) {
            e.stopPropagation();
            e.preventDefault();
        }
        return false;
    } else { // Everything else - empty editdiv and allow browser to paste content into it, then cleanup
        elem.innerHTML = "";
        waitforpastedata(elem, savedcontent);
        return true;
    }
}

function waitforpastedata(elem, savedcontent) {
    if (elem.childNodes && elem.childNodes.length > 0) {
        processpaste(elem, savedcontent);
    } else {
        that = {
            e: elem,
            s: savedcontent
        }
        that.callself = function() {
            waitforpastedata(that.e, that.s)
        }
        setTimeout(that.callself, 20);
    }
}

function removeStyles(el) {
    el.removeAttribute('style');

    if (el.childNodes.length > 0) {
        for (var child in el.childNodes) {
            /* filter element nodes only */
            if (el.childNodes[child].nodeType == 1)
                removeStyles(el.childNodes[child]);
        }
    }
}

function processpaste(elem, savedcontent) {

    // remove any style tags
    removeStyles(elem);

    // santize pasteddata
    pasteddata = zss_editor.strip_tags(elem.innerHTML, "<p><b><ul><ol><li><strong><i><em>");

    // set final
    elem.innerHTML = savedcontent + pasteddata;

    // wrap any unwrapped text elements in p tags
    var textnodes = zss_editor.getTextNodesIn($("#zss_editor_content")[0]);
    for (var i = 0; i < textnodes.length; i++) {
        if ($(textnodes[i]).parent().is("#zss_editor_content")) {
            $(textnodes[i]).wrap("<p>");
        }
    }

    // height changed after adding text
    zss_editor.dispatchContentHeightChanged();
}

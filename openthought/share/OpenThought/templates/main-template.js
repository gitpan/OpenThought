<!-- Include the OpenThought Javascript Library -->

<script language="JavaScript"><!--

// Are we using Netscape, IE, Mozilla, or Opera?  Set up a global variable
ns4 = false;
ie4 = false;
w3c = false;
opr = false;
knq = false;

// Test for browser types
if (document.layers) {
    ns4 = true;
}
else if (navigator.userAgent.indexOf("Opera")!=-1) {
    opr = true;
}
else if (document.getElementById) {
    w3c = true;
}
else if (document.all) {
    ie4 = true;
}
else {
    var wrong_browser = "<TMPL_VAR NAME=wrong_browser>";

    // Only popup the alert box if there is a message to display
    if(wrong_browser != "") {
        alert(wrong_browser);
    }
}

// The session id for this application
sessionid = '<TMPL_VAR NAME=session_id>';

// Don't allow select boxes to grow larger then this
maxSelectBoxWidth = <TMPL_VAR NAME=max_selectbox_width>;

// Set the current active (visible) layer
currentLayer = "";

// Automatically clear select lists before putting data into them?
autoClear = true;

// Instanciate the form element caching hash
formElement = new Object;

fetchStart   = '<TMPL_VAR NAME=fetch_start>';
fetchDisplay = '<TMPL_VAR NAME=fetch_display>';
fetchFinish  = '<TMPL_VAR NAME=fetch_finish>';

runmode = '';
runmodeParam = '<TMPL_VAR NAME=run_mode_param>';


// Deprecated: We now use CallUrl(), this is here temporarily for backwards
// compatability
function SendParameters() {
    var commFrame = 1;

    // Serialize the parameters we were passed into an XML Packet
    var XMLPacket = Hash2XML(GenParams(SortParams(SendParameters.arguments)));

    Send(SendParameters.arguments[0], commFrame, XMLPacket);
}

// This is the function that will be communicating with the server
function CallUrl() {
    var commFrame = 1;

    // Serialize the parameters we were passed into an XML Packet
    var XMLPacket = Hash2XML(GenParams(SortParams(CallUrl.arguments)));

    Send(CallUrl.arguments[0], commFrame, XMLPacket);
}

// This loads a new page in the content frame
function FetchHtml() {
    var commFrame = 0;

    // Serialize the parameters we were passed into an XML Packet
    var XMLPacket = Hash2XML(GenParams(SortParams(FetchHtml.arguments)));

    ExpireCache();
    Send(FetchHtml.arguments[0], commFrame, XMLPacket);
}

function Send(url, commFrame, XMLPacket) {

    var date = new Date();
    bench = "Params: " + date.getTime() + "\n";

    // Update the message on the status bar
    window.status = fetchStart;

    //var date = new Date();
    //bench += "Ser: " + date.getTime() + "\n";

    // Now that the XML packet is created, reset the runmode
    set_runmode('');

    // Post request to server via the form in the controlFrame
    //var date = new Date();
    //bench += "Sent: " + date.getTime() + "\n";

    parent.frames[commFrame].location.href = url + "?OpenThought=" + XMLPacket;
    parent.document.title = parent.contentFrame.document.title;

}

// Called by the CommFrame when data has arrived
function OpenThoughtUpdate(Content) {

    //var date = new Date();
    //bench += "Recv: " + date.getTime() + "\n";

    // Update the message on the status bar
    window.status = fetchDisplay;

    // Display everything if we received a decent response
    if (Content != null)
    {
        FillFields(Content);
    }
    // Something didn't go right, reply accordingly
    else
    {
        if(nullReply != "") {
            alert(nullReply);
        }
        return;
    }

    // Display text on the status bar stating that we received information
    window.status = fetchFinish;

    var date = new Date();
    bench += "Done: " + date.getTime() + "\n";
    //alert(bench);
    return;
}

// Digs through the browsers DOM hunting down a particular form element
function FindObject(element, d) {

    // If we have this particular object cached in our hash, use the cached
    // version (Just remember, Dr Suess wrote the "Cat in the Hat".  It's me
    // who wrote "The Cache in the Hash" ;-)
    if(typeof(formElement[element]) == "object") {
        return formElement[element];
    }

    var p,i,x;

    if(!d) {
        d = frames[0].document;
    }
    if((p = element.indexOf("?")) > 0 && parent.frames.length) {
        d = parent.frames[element.substring(p+1)].document;
        element = element.substring(0,p);
    }
    if(!(x = d[element]) && d.all) {
        x = d.all[element];
    }
    for (i=0;!x&&i<d.forms.length;i++) {
        x = d.forms[i][element];
    }
    for(i=0; !x && d.layers && i < d.layers.length; i++) {
        x = FindObject(element, d.layers[i].document);
    }
    if(!x && document.getElementById) {
        x = d.getElementById(element);
    }

    // Now that we found our Object, cache it for later use
    formElement[element] = x;

return x;
}

// Initialize and populate the Select list
function FillSelect(element, data)
{
    // If sent a string, and not an array, we just need to highlight an
    // existing item in the list, and not add anything
    if(typeof data == "string") {
        for (var i=0; i < element.options.length; i++) {
            if( element.options[i].value == data ) {
                element.selectedIndex = i;
            }
        }

    }
    // Actually add the items we were sent to the list
    else {
        // Clear any current OPTIONS from the SELECT
        //element.options.length = 0;
        if(((autoClear) &&
            ((typeof data[0] != "string") && (data[0] != "" ))) ||
            ((typeof data[0] == "string") && (data[0] == ""))) {

            while (element.options.length) element.options[0] = null;
            if((data.length == 1) && (data[0] == "")) {
                return;
            }
        }

        // For each record...
        for (var i=0; i < data.length; i++)
        {

            var text;
            var value;

            if (typeof data[0] == "string") {
                text  = data[0];
                value = data[1];

                if (data[1] == "") {
                    value = text;
                }
                i++;
            }
            else {
                text = data[i][0];
                value = data[i][1];

                if (data[i][1] == "") {
                    value = text;
                }
            }

            // Text cam't be null
           // if(text != undefined) {
                // If CutSelectBoxText is set, alter the length of the text to
                // lessen the need to the browser to resize the selectbox.
                // Netscape 4 does not resize selectboxes.
                if ((!ns4) && (maxSelectBoxWidth != 0))
                {
                    text = (text.substr(0,maxSelectBoxWidth));
                }

                // Add the new object to the SELECT list
                element.options[element.options.length] =
                                                    new Option(text, value);
            //}
        }
    }
}

// Put values into a text form field
function FillText(element, data)
{
    element.value = data;
}

// Select or unselect a checkbox form field
function FillCheck(element, data)
{
    if((data == "false") || (data == "FALSE") || (data == "False") ||
       (data == "unchecked") || (data < "1"))
    {
        element.checked = false;
    }
    else
    {
        element.checked = true;
    }
}

// Select a radio button
function FillRadio(element, value)
{
    for(var i=0; i<element.length; i++)
    {
        if(element[i].value == value)
        {
            element[i].checked = true;
        }
    }
}

// Take the data we received, and put it in it's appropriate field
function FillFields(Content)
{
    for (var fieldName in Content)
    {
        var object = FindObject(fieldName);

        // This is kinda silly, but radio buttons don't seem to return an
        // object.type, in some versions of Mozilla
        if((!ie4) && (object.type == undefined) && (object.length > 0))
        {
            object.type="radio";
        }

        if((object) && ( object.type )) {
            switch (object.type)
            {
                case "select":
                case "select-one":
                case "select-multiple":
                    FillSelect(object,Content[fieldName]);
                    break;

                case "text":
                case "password":
                case "textarea":
                case "hidden":
                    FillText(object, Content[fieldName]);
                    break;

                case "checkbox":
                    FillCheck(object, Content[fieldName]);
                    break;

                case "radio":
                    FillRadio(object, Content[fieldName]);
                    break;
            }
        }
        else if((w3c) && (object.innerHTML)) {
            object.innerHTML = Content[fieldName];
        }
    }

}

// Digs through all the parameters sent to the SendParameters function, and
// organizes them into categories
function SortParams(elements)
{
    var param  = new Object();
    var fields = new Array();
    var values = new Array();

    // The first parameter is the form url
    for(var i=1; i < elements.length; i++) {

        // If the parameter contains an equal sign (=), it's an expression
        if(elements[i].indexOf("=") != -1) {
            values[values.length] = elements[i];
        }
        // Otherwise, it's a form element
        else {
            fields[fields.length] = elements[i];
        }
    }

    param["fields"] = fields;
    param["expr"]   = values;

return param;
}

// Generates the key/value pairs to send to the server
function GenSettingParams()
{
    var param  = new Object();

    param["session_id"] = get_sessionid();

    param["need_script"] = 1;

    param["runmode_param"] = get_runmodeparam();

    if(get_runmode != "") {
        param["runmode"] = get_runmode();
    }

return param;
}

// Generates the key/value pairs to send to the server
function GenExprParams(elements)
{
    var param  = new Object();
    var keyval = new Array();

    for(var i=0; i < elements.length; i++) {

        keyval = elements[i].split("=");

        param[keyval[0]] = keyval[1];

        if( get_runmodeparam() == keyval[0] ) {
            set_runmode( keyval[1] );
        }
    }

return param;
}

// Generates the field parameters to send to the server
function GenFieldParams(elements)
{
    var param = new Object();

    for(var i=0; i < elements.length; i++)
    {
        var object = FindObject(elements[i]);

        // This is kinda silly, but radio buttons don't seem to return an
        // object.type, in some versions of Mozilla
        if((!ie4) && (object.type == undefined) && (object.length > 0))
        {
            object.type="radio";
        }

        if(( object ) && ( object.type )) {
            switch (object.type)
            {
                case "text":
                case "password":
                case "textarea":
                case "hidden":
                    param[elements[i]] = object.value;
                    break;

                case "select":
                case "select-one":
                case "select-multiple":
                    param[elements[i]] = SelectValue(object);
                    break;

                case "checkbox":
                    param[elements[i]] = CheckboxValue(object);
                    break;

                case "radio":
                    param[elements[i]] = RadioValue(object);
                    break;
            }
        }
        else if((w3c) && (object.innerHTML)) {
            param[elements[i]] = object.innerHTML;
        }

        if( get_runmodeparam() == elements[i] ) {
            set_runmode( param[elements[i]] );
        }

    }

return param;
}

// Build a single hash containing all the data to be sent to the server
function GenParams(elements) {

    var params = new Object();

    // Add the fields we were given, but only add it if there is at least one
    if(elements["fields"].length > 0) {
        params["fields"]  = GenFieldParams(elements["fields"]);
    }
    // Add key/pair values, but only if there is at least one
    if(elements["expr"].length > 0) {
        params["expr"]  = GenExprParams(elements["expr"]);
    }
    // Add settings, there will always be at least one
    params["settings"]  = GenSettingParams();

return params;
}

// Figure out which option is selected in our Select list
function SelectValue(element)
{
    if(element.selectedIndex >= 0) {
        return element.options[element.selectedIndex].value;
    }
    else {
        return -1;
    }
}

// Figure out which option is selected in our checkbox
function CheckboxValue(element)
{
    if(element.checked == true)
    {
        if(element.value == "on")
        {
            return "<TMPL_VAR NAME=checked_true_value>";
        }
        else
        {
            return element.value;
        }
    }
    else
    {
        return "<TMPL_VAR NAME=checked_false_value>";
    }

}

// Figure out which option is selected in our radio button
function RadioValue(element)
{
    for (var i=0; i <= element.length; i++)
    {
        if(element[i].checked == true)
        {
            return element[i].value;
        }
    }

    return "<TMPL_VAR NAME=checked_false_value>";
}

// Takes a fieldname as an argument, and gives that field the focus
function FocusField(element)
{
    FindObject(element).focus();
}

// Display an error message to the user
function DisplayError(msg)
{
    alert(msg);
}

// Convert our parameter hash into an XML object
function Hash2XML(hash)
{
    // Define the root element
    var xml = "<OpenThought>";

    // Loop through each child in the hash (fields and expr)
    for (var child in hash) {

        xml += "<" + child + ">";

        if(typeof(hash[child]) == "object") {

            // Now get every child of the children elements (grandchild)
            for(var grandchild in hash[child])
            {
                xml += "<" + grandchild + ">";
                xml += escape_xml(hash[child][grandchild]);
                xml += "</" + grandchild + ">";
            }
        }
        else {
            xml += escape_xml(hash[child]);
        }

        xml += "</" + child + ">";
    }
    xml += "</OpenThought>";

return xml;
}

function escape_xml( xmlchar ) {

    xmlchar = xmlchar.toString();

    if(xmlchar.indexOf("<") != -1) {

        var regexp = /\</g;
        xmlchar = xmlchar.replace( regexp, "\&lt;" );
    }

    if(xmlchar.indexOf(">") != -1) {

        var regexp = /\>/g;
        xmlchar = xmlchar.replace( regexp, "\&gt;" );
    }

    return escape(xmlchar);
}

// Used for the tabs - hide the current layer, show the new one
function showDiv(layerName)
{
   // First hide the layer, then set 'currentLayer' to the new layer, and
   // finally show the new layer
   if (ns4)
   {
      if(currentLayer != "") {
        frames[0].document.layers[currentLayer].visibility = "hide"
      }
      currentLayer = layerName;
      frames[0].document.layers[layerName].visibility = "show";
   }
   else if (ie4)
   {
      if(currentLayer != "") {
        frames[0].document.all[currentLayer].style.visibility = "hidden";
      }
      currentLayer = layerName;
      frames[0].document.all[layerName].style.visibility = "visible";
   }
   else if ((w3c) || (opr) || (knq))
   {

      if(currentLayer != "") {
        frames[0].document.getElementById(currentLayer).style.visibility = "hidden";

      }
      currentLayer = layerName;
      frames[0].document.getElementById(layerName).style.visibility = "visible";
   }
}

// Every call to find a form object is cached for later use.  If the underlying
// HTML is changed though, the values listed in the cache will be incorrect.
// The following function should be called anytime you change the page, or
// directly manipulate the name or location of a form element.
function ExpireCache() {

    formElement = "";

    // Instanciate the form element caching hash
    formElement = new Object;

}

// ------------------------------------------------------------------------//
//   Accessor Methods
//
//   The following methods are to access & change the values of
//   existing variables
// ------------------------------------------------------------------------//

function set_maxselectboxwidth(width) { maxSelectBoxWidth = width; }
function set_autoclear(val) {
    if(val < 1) {
         autoClear = false;
    }
    else {
        autoClear = true;
    }

}
function set_fetchstart(msg)   { fetchStart   = msg; }
function set_fetchdisplay(msg) { fetchDisplay = msg; }
function set_fetchfinish(msg)  { fetchFinish  = msg; }
function set_nullreply(msg)    { nullReply    = msg; }
function set_runmode(msg)      { runmode      = msg; }
function set_runmodeparam(msg) { runmodeParam = msg; }

function get_sessionid()         { return sessionid;    }
function get_maxselectboxwidth() { return maxSelectBoxWidth; }
function get_autoclear()         { return autoClear;    }
function get_fetchstart()        { return fetchStart;   }
function get_fetchdisplay()      { return fetchDisplay; }
function get_fetchfinish()       { return fetchFinish;  }
function get_nullreply()         { return nullReply;    }
function get_runmode()           { return runmode;      }
function get_runmodeparam()      { return runmodeParam; }

// -->
</script>

<!-- And they lived happily ever after, The End -->

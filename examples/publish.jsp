<%@ page import="java.util.*,com.navnorth.learningregistry.*" %>

<%
// default node and signing values
String nodeDomain = (request.getParameter("nodeDomain") != null) ? request.getParameter("nodeDomain") : "lrtest02.learningregistry.org"; 
String publicKeyLocation = (request.getParameter("publicKeyLocation") != null) ? request.getParameter("publicKeyLocation") : "keyserver.pgp.com/vkd/DownloadKey.event?keyid=0x8E155268359114B4";
String privateKey = (request.getParameter("privateKey") != null) ? request.getParameter("privateKey") : ""; 
String passPhrase = (request.getParameter("passPhrase") != null) ? request.getParameter("passPhrase") : ""; 

// Envelope parameters: these values will usually remain the same for all envelopes of the same schema and type
String resourceDataType = (request.getParameter("resourceDataType") != null) ? request.getParameter("resourceDataType") : "paradata"; 
String payloadPlacement = (request.getParameter("payloadPlacement") != null) ? request.getParameter("payloadPlacement") : "inline"; 
String payloadSchemaURL = "";  // deprecated, but still in the LR lib
// only allow 1 payload schema in this example
String[] payloadSchema = new String[] {(request.getParameter("payloadSchema") != null) ? request.getParameter("payloadSchema") : "LR Paradata 1.0"};

String defaultResData = "{\"activity\":{\"verb\":{\"action\":\"viewed\",\"measure\":{\"measureType\":\"count\",\"value\":\"1\"},\"context\":{},\"date\":\"2011-11-01\"},\"object\":{\"id\":\"http://google.com\"}}}";
String resourceData = (request.getParameter("resourceData") != null) ? request.getParameter("resourceData") : defaultResData;
String resourceURL = (request.getParameter("resourceURL") != null) ? request.getParameter("resourceURL") : "http://google.com"; 

// only allow 1 payload schema in this example
String[] keywords = new String[] {(request.getParameter("keywords") != null) ? request.getParameter("keywords") : "lr-test-data"};

// Identity data
String signer = (request.getParameter("signer") != null) ? request.getParameter("signer") : "";
String curator = (request.getParameter("curator") != null) ? request.getParameter("curator") : "";
String provider = (request.getParameter("provider") != null) ? request.getParameter("provider") : "";
String submitter = (request.getParameter("submitter") != null) ? request.getParameter("submitter") : "Navigation North";
String submitterType = (request.getParameter("submitterType") != null) ? request.getParameter("submitterType") : "agent";
String submissionTOS = (request.getParameter("submissionTOS") != null) ? request.getParameter("submissionTOS") : "http://creativecommons.org/licenses/by/3.0/";
String submissionAttribution = (request.getParameter("submissionAttribution") != null) ? request.getParameter("submissionAttribution") : "Copyright 2011 Navigation North: CC-BY-3.0";


//out.print("<pre>"+defaultResData+"</pre>");
//out.print("<pre>"+resourceData+"</pre>");

// if form submitted.
if (request.getParameter("publishNow") != null && request.getParameter("publishNow").length() > 0) 
{    
    
    // Setup signer
    LRSigner signerLR = new LRSigner(publicKeyLocation, privateKey, passPhrase);
    
    // Setup exporter
    int batchSize = 1;
    LRExporter exporterLR = new LRExporter(batchSize, nodeDomain);
    
    // Configure exporter
    try {
        exporterLR.configure();
    } 
    catch (LRException e) {
        return;
    }
    
    // Build resource envelope
    // In a production environment, you would likely put many envelopes into the exporter before sending the data
    LREnvelope doc = new LRSimpleDocument(resourceData, resourceDataType, resourceURL, curator, provider, keywords, payloadPlacement, payloadSchemaURL, payloadSchema, submitter, submitterType, submissionTOS, submissionAttribution, signer);
    
    // sign the doc
    if (privateKey.length() > 0 && passPhrase.length() > 0 && publicKeyLocation.length() > 0)
    {
        try {
            doc = signerLR.sign(doc);
        }
        catch (LRException e) {
            return;
        }
    }
    
    // Add envelope to exporter
    exporterLR.addDocument(doc);
    
    // Send data and get responses
    List<LRResponse> responses;
    try {
        responses = exporterLR.sendData();
    }
    catch(LRException e) {
        return;
    }
    
    //out.print("<pre>"+resourceData+"</pre>");
    
    // Parse responses
    out.print("<div style=\"background-color:#98afc7;margin:10px;padding:10px\"><h1>Publish Results</h2>");
    for (LRResponse res : responses)
    {
        out.print("<h2>Batch Results</h2>");
        out.print("Status Code: " + res.getStatusCode() + "<br/>");
        out.print("Status Reason: " + res.getStatusReason() + "<br/>");
        out.print("Batch Success: " + res.getBatchSuccess() + "<br/>");
        out.print("Batch Response: " + res.getBatchResponse() + "<br/><br/>");

        out.print("<h3>Published Resource(s)</h3>");        
        for(String id : res.getResourceSuccess())
        {
            out.print("Id: <a href=\"http://" + nodeDomain + "/harvest/getrecord?by_doc_ID=T&request_ID=" + id + "\" target=_\"blank\">" + id + "</a><br/>");
        }
        
        if (!res.getResourceFailure().isEmpty())
        {
            out.print("<br/>");
            out.print("<h3>Publish Errors</h3>");
            
            for(String message : res.getResourceFailure()) 
            {
                out.print("Error: " + message);
                out.print("<br/>");
            }
        }
    }
    out.print("</div><hr />");
}

%>



<form method="post" action="publish.jsp">
    <b>Node domain:</b> <input type="text" name="nodeDomain" value="<%= nodeDomain %>" size="60" /><br />
    <hr />
    
    <b>Resource URL:</b> <input type="text" name="resourceURL" value="<%= resourceURL %>" size="60" /><br />
    <b>Resource Data:</b> <br />
    <textarea name="resourceData" rows="5" cols="60"><%= resourceData %></textarea>
    <hr />

    <b>Payload Schema:</b> <input type="text" name="payloadSchema" value="<%= payloadSchema[0] %>" size="60" /><br />
    <b>Resource Data Type:</b> <input type="text" name="resourceDataType" value="<%= resourceDataType %>" size="60" /><br />
    <b>Payload Placement:</b> <input type="text" name="payloadPlacement" value="<%= payloadPlacement %>" size="60" /><br />
    
    <hr />
    <b>keywords:</b> <input type="text" name="keywords" value="<%= keywords[0] %>" size="60" /> (comma-delimited)<br />
    
    <hr />    
    <b>Signer:</b> <input type="text" name="signer" value="<%= signer %>" size="60" /><br />
    <b>Curator:</b> <input type="text" name="curator" value="<%= curator %>" size="60" /><br />
    <b>Provider:</b> <input type="text" name="provider" value="<%= provider %>" size="60" /><br />
    <b>Submitter:</b> <input type="text" name="submitter" value="<%= submitter %>" size="60" /><br />
    <b>Submitter Type:</b> <input type="text" name="submitterType" value="<%= submitterType %>" size="60" /><br />
    <b>Submission TOS:</b> <input type="text" name="submissionTOS" value="<%= submissionTOS %>" size="60" /><br />
    <b>Submission Attribution:</b> <input type="text" name="submissionAttribution" value="<%= submissionAttribution %>" size="60" /><br />

    <hr />
    <b>Public Key Location:</b> <input type="text" name="publicKeyLocation" value="<%= publicKeyLocation %>" size="60" /><br />
    <b>Pass Phrase:</b> <input type="text" name="passPhrase" value="<%= passPhrase %>" size="60" /><br />
    <b>Private Key:</b> <br />
    <textarea name="privateKey" rows="5" cols="60"><%= privateKey %></textarea><br />
    

    <input type="submit" name="publishNow" value="Publish to Node" />
</form>



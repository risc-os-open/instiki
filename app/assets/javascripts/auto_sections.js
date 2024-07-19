/* Variable depth automatic section numbering implemented by automatic
 * document scanning, looking for headers.
 *
 * This code is derived from an example in O'Reilly, "JavaScript: The
 * Definitive Guide" by David Flanagan, ISBN-10: 0-596-10199-6, ISBN-13:
 * 978-0-596-10199-2, 5th edition, section 15.9, p336.
 *
 * History
 * =======
 *
 * 13-Jun-2007 (ADH): Imported into Wiki structure.
 * 21-Mar-2011 (ADH): Imported into Instiki.
 */

/* This module defines a single maketoc() function and registers an onload
 * event handler so the function is automatically run when the document
 * finishes loading.  When it runs, maketoc() first looks for document
 * elements with IDs of "toc" and "under_toc". If there are no such elements
 * maketoc() does nothing. Otherwise, maketoc() traverses all child nodes
 * of "under_toc" to find all <h2> through <h6> tags. It creates a table of
 * contents, which it appends to the "toc" element. maketoc() adds section
 * numbers to each section heading and inserts a link back to the table of
 * contents before each heading. maketoc() generates links and anchors with
 * names that begin with "TOC", so you should avoid this prefix in your own
 * HTML.
 *
 * The entries in the generated TOC can be styled with CSS. All entries have
 * a class "TOCEntry". Entries also have a class that corresponds to the level
 * of the section heading. <h1> tags generate entries of class "TOCLevel1",
 * <h2> tags generate entries of class "TOCLevel2", and so on. Section numbers
 * inserted into headings have class "TOCSectNum" and the generated links back
 * to the TOC have class "TOCBackLink".
 *
 * By default, the generated links back to the TOC read "Contents".
 * Override this default (for internationalization, e.g.) by setting
 * the maketoc.backlinkText property to the desired text.
 */

function maketoc() {
    // Find the containers. If either is missing, return silently.
    var container = document.getElementById('toc');
    var searchNode = document.getElementById('under_toc');
    if (!searchNode && container) searchNode = container.parentNode;
    if (!container || !searchNode) return;

    // Traverse the document, adding all <h1>...<h6> tags to an array
    var sections = [];
    findSections(searchNode, sections);

    // Insert an anchor before the container element so we can link back to it
    var anchor = document.createElement("a");  // Create an <a> node
    anchor.name = "TOCtop";                    // Give it a name
    anchor.id = "TOCtop";                      // And an id (IE needs this)
    container.parentNode.insertBefore(anchor, container); // add before toc

    // Initialize an array that keeps track of section numbers
    var sectionNumbers = [0,0,0,0,0,0];
    var found = false;

    // Now loop through the section header elements we found
    for(var s = 0; s < sections.length; s++) {
        var section = sections[s];

        // Figure out what level heading it is
        var level = parseInt(section.tagName.charAt(1));
        if (isNaN(level) || level < 2 || level > 6) continue;
        found = true;

        // Increment the section number for this heading level
        // And reset all lower heading level numbers to zero
        sectionNumbers[level-1]++;
        for(var i = level; i < 6; i++) sectionNumbers[i] = 0;

        // Now combine section numbers for all heading levels
        // to produce a section number like 2.3.1
        var sectionNumber = "";
        for(i = 1; i < level; i++) {
            sectionNumber += sectionNumbers[i];
            if (i < level-1) sectionNumber += ".";
        }

        // Add the section number and a space to the section header title.
        // We place the number in a <span> to make it styleable.
        var frag = document.createDocumentFragment(); // to hold span and space
        var span = document.createElement("span");    // span to hold number
        span.className = "TOCSectNum";                // make it styleable
        span.appendChild(document.createTextNode(sectionNumber)); // add sect#
        frag.appendChild(span);                          // Add span to fragment
        frag.appendChild(document.createTextNode(". ")); // Then add a full stop and space
        section.insertBefore(frag, section.firstChild);  // Add both to header

        // Create an anchor to mark the beginning of this section.
        var anchor = document.createElement("a");
        anchor.name = "TOC"+sectionNumber;  // Name the anchor so we can link
        anchor.id = "TOC"+sectionNumber;    // In IE generated anchors need ids

        // Wrap the anchor around a link back to the TOC
        var link = document.createElement("a");
        link.href = "#TOCtop";
        link.className = "TOCBackLink";
        link.appendChild(document.createTextNode(maketoc.backlinkText));
        anchor.appendChild(link);

        // Insert the anchor and link immediately before the section header
        section.parentNode.insertBefore(anchor, section);

        // Now create a link to this section.
        var link = document.createElement("a");
        link.href = "#TOC" + sectionNumber;   // Set link destination
        link.innerHTML = section.innerHTML;   // Make link text same as heading

        // Place the link in a div that is styleable based on the level
        var entry = document.createElement("div");
        entry.className = "TOCEntry TOCLevel" + level; // For CSS styling
        entry.appendChild(link);

        // And add the div to the TOC container
        container.appendChild(entry);
    }

    // If we found anything, add the 'Contents' heading.

    if (found) {
        var heading = document.getElementById('toc_heading');

        if (heading) {
            var h2 = document.createElement('h2');
            h2.appendChild(document.createTextNode(maketoc.headingText));
            heading.appendChild(h2);
            heading.appendChild(document.createElement('p'));
        }

        container.appendChild(document.createElement('p'));
    }

    // This method recursively traverses the tree rooted at node n, looking
    // for <h1> through <h6> tags and appends them to the sections array.
    function findSections(n, sects) {
        // Loop through all the children of n
        for(var m = n.firstChild; m != null; m = m.nextSibling) {
            // Skip any  nodes that are not elements.
            if (m.nodeType != 1 /* Node.Element_NODE */) continue;
            // Skip the container element since it may have its own heading
            if (m == container) continue;
            // As an optimization, skip <p> tags since headings are not
            // supposed to appear inside paragraphs.  (We could also skip
            // lists, <pre> tags, etc., but <p> is the most common one.)
            // XHTML documents tend to return lower case elements, HTML
            // documents tend to return upper case elements.
            if (m.tagName == "p" || m.tagName == "P") continue;  // optimization

            // If we didn't skip the child node, check whether it is a heading.
            // If so, add it to the array.  Otherwise, recurse on it.
            // Note that the DOM is interface-based not class-based so we
            // cannot simply test whether (m instanceof HTMLHeadingElement).
            if (m.tagName.length==2 && (m.tagName.charAt(0)=="h" || m.tagName.charAt(0)=="H")) sects.push(m);
            else findSections(m, sects);
        }
    }
}

// Default text for the Contents section heading
maketoc.headingText = "Contents";
// This is the default text of links back to the TOC
maketoc.backlinkText = "Contents";

// Register maketoc() to run automatically when the document finishes loading
if (window.addEventListener) window.addEventListener("load", maketoc, false);
else if (window.attachEvent) window.attachEvent("onload", maketoc);

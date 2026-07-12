/*
 * Contact form submit handler.
 *
 * Request contract expected by the receiving endpoint (an external Azure Function,
 * not part of this repo): a POST with a JSON body of
 *   { name, email, message, company, renderedAt }
 * "company" is a honeypot field that must always be empty for a genuine submission —
 * reject the request if it isn't. "renderedAt" is the epoch-ms timestamp (as a string)
 * of when the form was rendered; reject requests where (now - renderedAt) is below a
 * few seconds, since real users can't fill and submit the form that fast. The endpoint
 * must also set Access-Control-Allow-Origin for this site's origin(s) and handle the
 * CORS preflight OPTIONS request, since the JSON content-type triggers one.
 *
 * Any 2xx response is treated as success; anything else (including a missing/empty
 * endpoint) shows the inline error state.
 */
(function () {
  var script = document.currentScript;
  var form = document.getElementById("contact-form");
  if (!form || !script) {
    return;
  }

  var renderedAt = document.getElementById("contact-rendered-at");
  if (renderedAt) {
    renderedAt.value = String(Date.now());
  }

  var submitButton = document.getElementById("contact-submit");
  var status = document.getElementById("contact-status");
  var sendingText = script.getAttribute("data-sending-text");
  var successText = script.getAttribute("data-success-text");
  var errorText = script.getAttribute("data-error-text");

  function setStatus(text, isError) {
    if (!status) {
      return;
    }
    status.textContent = text;
    status.classList.toggle("text-danger", !!isError);
    status.classList.toggle("text-success", !isError && !!text);
  }

  form.addEventListener("submit", function (event) {
    event.preventDefault();

    var endpoint = form.getAttribute("data-endpoint");
    if (!endpoint) {
      setStatus(errorText, true);
      return;
    }

    var payload = {
      name: document.getElementById("contact-name").value,
      email: document.getElementById("contact-email").value,
      message: document.getElementById("contact-message").value,
      company: document.getElementById("contact-company").value,
      renderedAt: renderedAt ? renderedAt.value : "",
    };

    submitButton.disabled = true;
    setStatus(sendingText, false);

    fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    })
      .then(function (response) {
        if (!response.ok) {
          throw new Error("Request failed with status " + response.status);
        }
        form.reset();
        if (renderedAt) {
          renderedAt.value = String(Date.now());
        }
        setStatus(successText, false);
        submitButton.disabled = true;
      })
      .catch(function () {
        setStatus(errorText, true);
        submitButton.disabled = false;
      });
  });
})();

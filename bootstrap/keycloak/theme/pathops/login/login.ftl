<#import "template.ftl" as layout>

<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password') displayInfo=false; section>
  <#if section = "header">
    PathOps
  <#elseif section = "form">

    <div class="pathops-login-shell">

      <#assign googleProvider = "">
      <#if social?? && social.providers??>
        <#list social.providers as p>
          <#if p.alias?lower_case == "google">
            <#assign googleProvider = p.loginUrl>
          </#if>
        </#list>
      </#if>

      <#if googleProvider?has_content>
        <div class="pathops-google-section">
          <a class="pathops-google-button" href="${googleProvider}">
            Sign in with Google
          </a>
        </div>
      </#if>

      <details class="pathops-admin-details">
        <summary class="pathops-admin-summary">Admin login</summary>

        <div class="pathops-admin-panel">
          <form id="kc-form-login" class="pathops-form" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">

            <#if !usernameHidden?? || !usernameHidden>
              <div class="pathops-form-group">
                <label for="username" class="pathops-label">
                  <#if !realm.loginWithEmailAllowed>
                    ${msg("username")}
                  <#elseif !realm.registrationEmailAsUsername>
                    ${msg("usernameOrEmail")}
                  <#else>
                    ${msg("email")}
                  </#if>
                </label>

                <input
                  tabindex="2"
                  id="username"
                  class="pathops-input"
                  name="username"
                  value="${(login.username!'')}"
                  type="text"
                  autofocus
                  autocomplete="username"
                  aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                />

                <#if messagesPerField.existsError('username','password')>
                  <div class="pathops-field-error">
                    ${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}
                  </div>
                </#if>
              </div>
            </#if>

            <div class="pathops-form-group">
              <label for="password" class="pathops-label">${msg("password")}</label>

              <input
                tabindex="3"
                id="password"
                class="pathops-input"
                name="password"
                type="password"
                autocomplete="current-password"
                aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
              />
            </div>

            <#if realm.rememberMe && !usernameHidden?? || !usernameHidden>
              <div class="pathops-checkbox-row">
                <label class="pathops-checkbox-label">
                  <input tabindex="5" id="rememberMe" name="rememberMe" type="checkbox" <#if login.rememberMe??>checked</#if>>
                  <span>${msg("rememberMe")}</span>
                </label>
              </div>
            </#if>

            <div class="pathops-submit-row">
              <input
                tabindex="7"
                class="pathops-submit-button"
                name="login"
                id="kc-login"
                type="submit"
                value="${msg("doLogIn")}"
              />
            </div>
          </form>
        </div>
      </details>
    </div>

  </#if>
</@layout.registrationLayout>
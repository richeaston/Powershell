# ReplaceCertsIIS
Replace a Certificate on an IIS server and rebind to a new cert

Remove an old certificate [subjectname of old cert] and unbind from https sites, then import new certificate (prompt for PFX password) and then rebind all sites not excluded in [sitetoexclude], Will ignore http sites.


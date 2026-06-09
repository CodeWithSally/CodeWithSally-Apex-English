/**
 * Public REST endpoint for the "Contact Us" form.
 *
 *   POST /services/apexrest/lead
 *   Body: { "firstName": "...", "lastName": "...", "email": "...", "message": "..." }
 *
 * When an @HttpPost method has parameters, Apex automatically maps the matching
 * keys from the JSON request body into them. The returned Lead is automatically
 * serialized back to JSON for the response.
 */
@RestResource(urlMapping='/lead/*')
global with sharing class LeadResource {


    @HttpPost
    global static Lead createLead(String firstName, String lastName, String email, String message) {

        
        Lead lead = new Lead(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            Description = message,
            Company = 'Web Contact Form',
            LeadSource = 'Web'
        );
        insert lead;
        return lead;
    }
}

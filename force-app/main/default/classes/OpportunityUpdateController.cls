/**
 * @description Controller for Opportunity Update Form
 * Handles data retrieval, updates, PDF generation, and email notification
 * @author Salesforce Platform Expert
 * @date 2026-02-17
 */
public with sharing class OpportunityUpdateController {
    
    /**
     * @description Retrieves Opportunity and related Account data
     * @param opportunityId The ID of the Opportunity record
     * @return OpportunityData wrapper containing Opportunity and Account info
     */
    @AuraEnabled(cacheable=false)
    public static OpportunityData getOpportunityData(Id opportunityId) {
        try {
            Opportunity opp = [
                SELECT Id, Name, Amount, AccountId, Account.Name, Account.NumberOfEmployees
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            
            OpportunityData data = new OpportunityData();
            data.opportunityId = opp.Id;
            data.opportunityName = opp.Name;
            data.accountId = opp.AccountId;
            data.accountName = opp.Account.Name;
            data.amount = opp.Amount;
            data.numberOfEmployees = opp.Account.NumberOfEmployees;
            
            return data;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving opportunity data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates Opportunity and Account, generates PDF, and sends email
     * @param opportunityId The ID of the Opportunity record
     * @param amount The new Amount value
     * @param numberOfEmployees The new Number of Employees value
     * @return String success message
     */
    @AuraEnabled
    public static String updateAndNotify(Id opportunityId, Decimal amount, Integer numberOfEmployees) {
        try {
            // Retrieve Opportunity and Account
            Opportunity opp = [
                SELECT Id, Name, Amount, AccountId, Account.Name, Account.NumberOfEmployees
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            
            // Store data for PDF before update
            String opportunityName = opp.Name;
            String accountName = opp.Account.Name;
            
            // Update records
            opp.Amount = amount;
            
            Account acc = new Account(
                Id = opp.AccountId,
                NumberOfEmployees = numberOfEmployees
            );
            
            // Perform DML operations
            update opp;
            update acc;
            
            // Generate PDF
            Blob pdfBlob = generatePDF(opportunityName, accountName, amount, numberOfEmployees);
            
            // Send Email
            sendEmailWithPDF(opportunityName, accountName, pdfBlob);
            
            return 'Success! Records updated and email sent to Customer Success.';
            
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating records: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error processing request: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generates PDF using Visualforce page
     * @param opportunityName Name of the Opportunity
     * @param accountName Name of the Account
     * @param amount Updated Amount value
     * @param numberOfEmployees Updated Number of Employees value
     * @return Blob PDF content
     */
    private static Blob generatePDF(String opportunityName, String accountName, Decimal amount, Integer numberOfEmployees) {
        // Create page reference
        PageReference pdfPage = Page.OpportunityUpdatePDF;
        pdfPage.getParameters().put('opportunityName', opportunityName);
        pdfPage.getParameters().put('accountName', accountName);
        pdfPage.getParameters().put('amount', String.valueOf(amount));
        pdfPage.getParameters().put('numberOfEmployees', String.valueOf(numberOfEmployees));
        
        // Generate PDF blob
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContent();
        }
        
        return pdfBlob;
    }
    
    /**
     * @description Sends email with PDF attachment to Customer Success
     * @param opportunityName Name of the Opportunity
     * @param accountName Name of the Account
     * @param pdfBlob PDF content as Blob
     */
    private static void sendEmailWithPDF(String opportunityName, String accountName, Blob pdfBlob) {
        // Create email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        // Set recipient
        email.setToAddresses(new String[] { 'nhsthakkar@gmail.com' });
        
        // Set subject
        email.setSubject('Opportunity fields updated - ' + opportunityName);
        
        // Set email body
        String emailBody = 'See attached PDF related to opportunity updates for ' + accountName + ' client.';
        email.setPlainTextBody(emailBody);
        email.setHtmlBody(emailBody);
        
        // Create PDF attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Opportunity_Update_' + opportunityName.replaceAll('[^a-zA-Z0-9]', '_') + '.pdf');
        attachment.setBody(pdfBlob);
        attachment.setContentType('application/pdf');
        
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        
        // Send email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
    
    /**
     * @description Wrapper class for Opportunity and Account data
     */
    public class OpportunityData {
        @AuraEnabled public Id opportunityId;
        @AuraEnabled public String opportunityName;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Integer numberOfEmployees;
    }
}
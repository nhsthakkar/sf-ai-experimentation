/**
 * @description Controller for OpportunityUpdatePDF Visualforce page
 * Handles data retrieval for PDF generation
 * @author Salesforce Platform Expert
 * @date 2026-02-17
 */
public with sharing class OpportunityUpdatePDFController {
    
    public String opportunityName { get; set; }
    public String accountName { get; set; }
    public Decimal amount { get; set; }
    public Integer numberOfEmployees { get; set; }
    
    /**
     * @description Constructor - retrieves parameters from URL
     */
    public OpportunityUpdatePDFController() {
        opportunityName = ApexPages.currentPage().getParameters().get('opportunityName');
        accountName = ApexPages.currentPage().getParameters().get('accountName');
        
        String amountParam = ApexPages.currentPage().getParameters().get('amount');
        if (String.isNotBlank(amountParam)) {
            amount = Decimal.valueOf(amountParam);
        }
        
        String employeesParam = ApexPages.currentPage().getParameters().get('numberOfEmployees');
        if (String.isNotBlank(employeesParam)) {
            numberOfEmployees = Integer.valueOf(employeesParam);
        }
    }
}
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getOpportunityData from '@salesforce/apex/OpportunityUpdateController.getOpportunityData';
import updateAndNotify from '@salesforce/apex/OpportunityUpdateController.updateAndNotify';

export default class OpportunityUpdateForm extends LightningElement {
    @api recordId; // Opportunity Id from record page
    
    isModalOpen = false;
    isLoading = false;
    
    // Data properties
    opportunityName = '';
    accountName = '';
    amount = 0;
    numberOfEmployees = 0;
    
    // Original data for reference
    originalAmount = 0;
    originalEmployees = 0;
    
    /**
     * Opens the modal and loads opportunity data
     */
    handleOpenModal() {
        this.isModalOpen = true;
        this.isLoading = true;
        this.loadOpportunityData();
    }
    
    /**
     * Closes the modal and resets state
     */
    handleCloseModal() {
        this.isModalOpen = false;
        this.resetForm();
    }
    
    /**
     * Loads opportunity and account data from Apex
     */
    loadOpportunityData() {
        getOpportunityData({ opportunityId: this.recordId })
            .then(result => {
                this.opportunityName = result.opportunityName;
                this.accountName = result.accountName;
                this.amount = result.amount || 0;
                this.numberOfEmployees = result.numberOfEmployees || 0;
                
                // Store original values
                this.originalAmount = this.amount;
                this.originalEmployees = this.numberOfEmployees;
                
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', this.getErrorMessage(error), 'error');
                this.handleCloseModal();
            });
    }
    
    /**
     * Handles amount field change
     */
    handleAmountChange(event) {
        this.amount = event.target.value;
    }
    
    /**
     * Handles number of employees field change
     */
    handleEmployeesChange(event) {
        this.numberOfEmployees = event.target.value;
    }
    
    /**
     * Validates and submits the form
     */
    handleSubmit() {
        // Validate required fields
        if (!this.validateForm()) {
            return;
        }
        
        this.isLoading = true;
        
        updateAndNotify({
            opportunityId: this.recordId,
            amount: parseFloat(this.amount),
            numberOfEmployees: parseInt(this.numberOfEmployees, 10)
        })
            .then(result => {
                this.showToast('Success', result, 'success');
                this.handleCloseModal();
                // Refresh the record page
                eval("$A.get('e.force:refreshView').fire();");
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', this.getErrorMessage(error), 'error');
            });
    }
    
    /**
     * Validates form inputs
     */
    validateForm() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        
        if (!allValid) {
            this.showToast('Error', 'Please fix the validation errors', 'error');
            return false;
        }
        
        // Additional validation for Number of Employees
        const employees = parseInt(this.numberOfEmployees, 10);
        if (employees < 10 || employees > 100000) {
            this.showToast('Error', 'Number of Employees must be between 10 and 100,000', 'error');
            return false;
        }
        
        return true;
    }
    
    /**
     * Resets form to initial state
     */
    resetForm() {
        this.isLoading = false;
        this.amount = this.originalAmount;
        this.numberOfEmployees = this.originalEmployees;
    }
    
    /**
     * Shows a toast notification
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
    /**
     * Extracts error message from error object
     */
    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        } else if (error.message) {
            return error.message;
        }
        return 'An unknown error occurred';
    }
}
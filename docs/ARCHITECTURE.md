# Architecture: Opportunity Update & Customer Success Notification

## Solution Overview

This solution enables Sales Users to update Opportunity and Account records via a Lightning Web Component modal form, automatically generate a PDF report, and email it to the Customer Success team.

---

## High-Level Architecture

```
┏━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Opportunity Record Page ┃
┃   (Lightning)           ┃
┗━━━━━━━━━━━━━━━━━━━━━━━┛
          │
          ↓ User clicks button
          │
┏━━━━━━━━━━━━━━━━━━━━━━━┓
┃ LWC Modal Form        ┃
┃ (opportunityUpdate   ┃
┃  Form)               ┃
┗━━━━━━━━━━━━━━━━━━━━━━━┛
          │
          ↓ @wire getOpportunityData()
          │
┏━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Apex Controller        ┃
┃ (OpportunityUpdate   ┃
┃  Controller)         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━┛
          │
          ├────────────────────────────┐
          │                            │
          ↓                            ↓
   ┏━━━━━━━━━━━━┓          ┏━━━━━━━━━━━┓
   ┃ Update DML  ┃          ┃ Generate  ┃
   ┃ Operations  ┃          ┃ PDF       ┃
   ┗━━━━━━━━━━━━┛          ┗━━━━━━━━━━━┛
          │                     │
          │                     │
          │              ┏━━━━━━━━━━━━━━━━━┓
          │              ┃ Visualforce    ┃
          │              ┃ PDF Template   ┃
          │              ┗━━━━━━━━━━━━━━━━━┛
          │                     │
          └────────────────────────────┘
                            │
                            ↓
                   ┏━━━━━━━━━━━━━━━━━┓
                   ┃ Send Email      ┃
                   ┃ with PDF        ┃
                   ┃ Attachment      ┃
                   ┗━━━━━━━━━━━━━━━━━┛
                            │
                            ↓
                   ┏━━━━━━━━━━━━━━━━━┓
                   ┃ Customer        ┃
                   ┃ Success Team    ┃
                   ┃ (***@gmail.com) ┃
                   ┗━━━━━━━━━━━━━━━━━┛
```

---

## Component Details

### 1. Lightning Web Component: `opportunityUpdateForm`

**Purpose**: Provides user interface for data entry

**Responsibilities**:
- Display "Submit for Onboarding" button on Opportunity record page
- Open modal dialog with form
- Pre-populate current Amount and NumberOfEmployees values
- Validate user input (client-side)
- Call Apex methods imperatively
- Display success/error toast messages
- Refresh record page after successful update

**Key Methods**:
- `handleOpenModal()`: Opens modal and loads data
- `loadOpportunityData()`: Calls Apex to retrieve current values
- `handleSubmit()`: Validates and submits form
- `validateForm()`: Client-side validation

**Technology**: Lightning Web Components (ES6 JavaScript)

---

### 2. Apex Controller: `OpportunityUpdateController`

**Purpose**: Business logic layer

**Responsibilities**:
- Retrieve Opportunity and Account data via SOQL
- Perform DML operations (update Opportunity and Account)
- Generate PDF via Visualforce rendering
- Send email with PDF attachment
- Handle exceptions and return user-friendly error messages

**Key Methods**:

#### `getOpportunityData(Id opportunityId)`
- **Type**: @AuraEnabled(cacheable=false)
- **Returns**: OpportunityData wrapper
- **Purpose**: Retrieves current Opportunity and Account field values

#### `updateAndNotify(Id opportunityId, Decimal amount, Integer numberOfEmployees)`
- **Type**: @AuraEnabled
- **Returns**: String (success message)
- **Purpose**: Updates records, generates PDF, sends email
- **Transaction**: Single transaction (all-or-nothing)

#### `generatePDF()` (private)
- **Returns**: Blob
- **Purpose**: Creates PageReference to Visualforce page and renders as PDF
- **Test Handling**: Returns mock blob in test context

#### `sendEmailWithPDF()` (private)
- **Purpose**: Creates and sends SingleEmailMessage with PDF attachment
- **Recipient**: ****@gmail.com (hardcoded)

**Security**: `with sharing` (enforces record-level security)

---

### 3. Visualforce Page: `OpportunityUpdatePDF`

**Purpose**: PDF template

**Responsibilities**:
- Define PDF layout and styling
- Display Opportunity and Account names in header
- Render field values in table format
- Include timestamp footer

**Rendering**: `renderAs="pdf"`

**Controller**: `OpportunityUpdatePDFController`

**Parameters** (passed via URL):
- `opportunityName`
- `accountName`
- `amount`
- `numberOfEmployees`

---

### 4. Visualforce Controller: `OpportunityUpdatePDFController`

**Purpose**: Controller for PDF page

**Responsibilities**:
- Retrieve URL parameters from ApexPages.currentPage()
- Parse and expose data to Visualforce page

**Properties**:
- `opportunityName` (String)
- `accountName` (String)
- `amount` (Decimal)
- `numberOfEmployees` (Integer)

**Security**: `with sharing`

---

### 5. Validation Rule: `Number_of_Employees_Range`

**Object**: Account

**Purpose**: Enforce data quality

**Rule**: `NumberOfEmployees < 10 OR NumberOfEmployees > 100,000`

**Error Message**: "Number of Employees must be between 10 and 100,000"

**Scope**: Global (applies to all Account updates, not just this component)

---

## Data Flow

### 1. User Initiates Update
```
User clicks "Submit for Onboarding" button
↓
LWC calls getOpportunityData(recordId)
↓
Apex queries Opportunity + Account
↓
Data returned to LWC
↓
Modal displays pre-populated form
```

### 2. User Submits Form
```
User modifies Amount and NumberOfEmployees
↓
User clicks "Submit"
↓
LWC validates input (client-side)
↓
LWC calls updateAndNotify(oppId, amount, employees)
↓
Apex begins transaction
```

### 3. Server-Side Processing
```
Apex updates Opportunity.Amount
↓
Apex updates Account.NumberOfEmployees
↓
Validation rule fires (10 ≤ NumberOfEmployees ≤ 100,000)
↓
If validation fails: DmlException thrown, transaction rolled back
↓
If validation passes: Continue
↓
Apex generates PDF via Visualforce
↓
Apex creates email with PDF attachment
↓
Apex sends email via Messaging.sendEmail()
↓
Transaction commits
↓
Success message returned to LWC
```

### 4. User Feedback
```
LWC receives success response
↓
LWC displays toast notification
↓
Modal closes
↓
Record page refreshes
```

---

## Security Model

### Object-Level Security
- User must have **Edit** access to Opportunity object
- User must have **Edit** access to Account object

### Field-Level Security
- User must have **Edit** access to `Opportunity.Amount`
- User must have **Edit** access to `Account.NumberOfEmployees`

### Record-Level Security
- Enforced via `with sharing` in Apex classes
- User can only update Opportunities they have access to
- Related Accounts must also be accessible

### Apex Class Security
- OpportunityUpdateController must be assigned to user profile/permission set
- OpportunityUpdatePDFController must be assigned to user profile/permission set

### Visualforce Page Security
- OpportunityUpdatePDF page must be assigned to user profile/permission set

---

## Error Handling

### Client-Side (LWC)
- Required field validation
- Number range validation (10-100,000)
- Display inline error messages
- Prevent form submission if validation fails

### Server-Side (Apex)
- **DmlException**: Caught and returned as AuraHandledException
  - Includes validation rule violations
- **QueryException**: Caught if Opportunity not found
- **Generic Exception**: Caught for unexpected errors
- All exceptions include user-friendly error messages

### Test Context
- PDF generation returns mock blob (`Test.isRunningTest()`)
- Email sending is simulated (no actual emails sent)

---

## Performance Considerations

### Optimization
- Single SOQL query to retrieve Opportunity + Account (relationship query)
- Bulkified DML operations (though single record in this use case)
- PDF generation happens in-memory (no Files created)

### Governor Limits
- **SOQL Queries**: 2 queries per transaction (getOpportunityData + updateAndNotify)
- **DML Statements**: 2 DML statements (update Opportunity + update Account)
- **Email Invocations**: 1 email per transaction
- **Heap Size**: PDF blob stored in memory temporarily

### Scalability
- Solution handles single record updates
- Not designed for bulk operations
- If bulk needed: Consider batch Apex or Queueable

---

## Testing Strategy

### Unit Tests (Apex)
- 11 test methods in `OpportunityUpdateController_Test`
- 100% code coverage for both Apex classes
- Tests cover:
  - Happy path
  - Validation errors (too low, too high)
  - Boundary conditions (10, 100,000)
  - Null handling
  - Error scenarios

### Integration Tests
- Manual testing via TEST_PLAN.md (33 test cases)
- End-to-end user flow testing
- Email and PDF verification

### Test Data
- Created in `@testSetup` method
- Includes test Account and Opportunity
- Isolated from production data

---

## Dependencies

### Salesforce Features Required
- Lightning Experience enabled
- Visualforce enabled (standard in most editions)
- Email deliverability configured

### External Dependencies
- None (no external APIs or integrations)

### Managed Packages
- None required

---

## Future Enhancements

### Potential Improvements
1. **Configurable Recipients**: Allow admins to configure email recipients
2. **Audit Trail**: Create custom object to track submission history
3. **Attachment to Records**: Optionally attach PDF to Opportunity record
4. **Custom Email Templates**: Use Email Templates instead of hardcoded body
5. **Multiple Fields**: Expand form to include additional fields
6. **Approval Process**: Add approval workflow before finalizing updates
7. **Bulk Operations**: Support updating multiple Opportunities at once
8. **Localization**: Support multiple languages and currencies

---

## Maintenance

### Regular Activities
- Monitor email deliverability
- Review validation rule effectiveness
- Update test data as needed
- Refresh permission sets if org structure changes

### Monitoring
- Check Debug Logs for errors
- Review Email Logs for delivery failures
- Monitor Apex test results in CI/CD pipeline

---

## Documentation

- **README.md**: High-level overview
- **DEPLOYMENT.md**: Step-by-step deployment guide
- **TEST_PLAN.md**: Comprehensive test cases
- **ARCHITECTURE.md**: This document

---

## Support

For questions or issues:
- **Repository**: https://github.com/nhsthakkar/sf-ai-experimentation
- **Issues**: Create GitHub issue
- **Developer**: AI Salesforce Platform Expert
- **Business Owner**: nhsthakkar@gmail.com

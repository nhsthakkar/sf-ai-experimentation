# Test Plan: Opportunity Update & Customer Success Notification

## Test Environment Setup
- **Salesforce Org**: Developer/Sandbox
- **Test User**: Sales User with standard Opportunity/Account access
- **Test Data**: 
  - 1 Account: "ACME Corporation" with 500 employees
  - 1 Opportunity: "ACME Q1 Deal" with $100,000 amount

---

## Unit Test Coverage (Apex)

### Executed via: `OpportunityUpdateController_Test`

| Test Method | Coverage | Status |
|------------|----------|--------|
| testGetOpportunityData_Success | Data retrieval | ✅ |
| testGetOpportunityData_InvalidId | Error handling | ✅ |
| testUpdateAndNotify_Success | Happy path | ✅ |
| testUpdateAndNotify_ValidationError_TooLow | Validation (< 10) | ✅ |
| testUpdateAndNotify_ValidationError_TooHigh | Validation (> 100k) | ✅ |
| testUpdateAndNotify_BoundaryMinimum | Boundary (10) | ✅ |
| testUpdateAndNotify_BoundaryMaximum | Boundary (100k) | ✅ |
| testUpdateAndNotify_NullAmount | Null handling | ✅ |
| testPDFGeneration | PDF mock | ✅ |
| testVFController | VF controller | ✅ |
| testVFController_EmptyParams | VF null handling | ✅ |

**Expected Coverage**: 100% for OpportunityUpdateController, 100% for OpportunityUpdatePDFController

---

## Functional Test Cases

### TC-001: Happy Path - Successful Update
**Objective**: Verify complete end-to-end flow with valid data

**Pre-conditions**:
- User is on Opportunity record page
- Opportunity has Amount = $100,000
- Account has NumberOfEmployees = 500

**Steps**:
1. Click "Submit for Onboarding" button
2. Verify modal opens with pre-populated values
3. Update Amount to $150,000
4. Update Number of Employees to 750
5. Click "Submit"

**Expected Results**:
- ✅ Success toast message displayed
- ✅ Opportunity.Amount updated to $150,000
- ✅ Account.NumberOfEmployees updated to 750
- ✅ Email sent to *****@gmail.com
- ✅ Email subject: "Opportunity fields updated - ACME Q1 Deal"
- ✅ Email body mentions "ACME Corporation"
- ✅ PDF attached with correct data in table format
- ✅ PDF header shows Opportunity and Account names

**Status**: ⬜ Not Executed | ✅ Pass | ❌ Fail

---

### TC-002: Validation - Number of Employees Too Low
**Objective**: Verify validation rule prevents values < 10

**Steps**:
1. Open modal
2. Set Number of Employees to 5
3. Click "Submit"

**Expected Results**:
- ❌ Validation error displayed
- ❌ Records NOT updated
- ❌ Email NOT sent
- ✅ User remains on modal with error message

**Status**: ⬜

---

### TC-003: Validation - Number of Employees Too High
**Objective**: Verify validation rule prevents values > 100,000

**Steps**:
1. Open modal
2. Set Number of Employees to 150,000
3. Click "Submit"

**Expected Results**:
- ❌ Validation error displayed
- ❌ Records NOT updated
- ❌ Email NOT sent

**Status**: ⬜

---

### TC-004: Boundary - Minimum Valid Value (10)
**Objective**: Verify minimum boundary is accepted

**Steps**:
1. Open modal
2. Set Number of Employees to exactly 10
3. Click "Submit"

**Expected Results**:
- ✅ Update successful
- ✅ Email sent with PDF

**Status**: ⬜

---

### TC-005: Boundary - Maximum Valid Value (100,000)
**Objective**: Verify maximum boundary is accepted

**Steps**:
1. Open modal
2. Set Number of Employees to exactly 100,000
3. Click "Submit"

**Expected Results**:
- ✅ Update successful
- ✅ Email sent with PDF

**Status**: ⬜

---

### TC-006: Required Field - Amount Empty
**Objective**: Verify Amount field is required

**Steps**:
1. Open modal
2. Clear Amount field
3. Click "Submit"

**Expected Results**:
- ❌ Client-side validation error
- ❌ Form cannot be submitted
- ✅ Error message: "Complete this field"

**Status**: ⬜

---

### TC-007: Required Field - Number of Employees Empty
**Objective**: Verify Number of Employees field is required

**Steps**:
1. Open modal
2. Clear Number of Employees field
3. Click "Submit"

**Expected Results**:
- ❌ Client-side validation error
- ❌ Form cannot be submitted

**Status**: ⬜

---

### TC-008: Modal Cancel
**Objective**: Verify cancel functionality

**Steps**:
1. Open modal
2. Change Amount to $200,000
3. Click "Cancel"
4. Re-open modal

**Expected Results**:
- ✅ Modal closes without saving
- ✅ Original values remain unchanged
- ✅ Re-opening modal shows original values

**Status**: ⬜

---

### TC-009: PDF Format Verification
**Objective**: Verify PDF content and formatting

**Steps**:
1. Complete successful update (TC-001)
2. Check email inbox
3. Download and open PDF attachment

**Expected Results**:
- ✅ PDF filename: "Opportunity_Update_ACME_Q1_Deal.pdf"
- ✅ Header line 1: "Opportunity Name: ACME Q1 Deal"
- ✅ Header line 2: "Account Name: ACME Corporation"
- ✅ Table with 2 columns: "Field Name" and "Value"
- ✅ Row 1: "Amount" | "$150,000.00"
- ✅ Row 2: "Number of Employees" | "750"
- ✅ Table has borders
- ✅ Footer with timestamp

**Status**: ⬜

---

### TC-010: Email Content Verification
**Objective**: Verify email formatting

**Steps**:
1. Complete successful update
2. Check email received at *****@gmail.com

**Expected Results**:
- ✅ From: Salesforce org email
- ✅ To: nhsthakkar@gmail.com
- ✅ Subject: "Opportunity fields updated - ACME Q1 Deal"
- ✅ Body: "See attached PDF related to opportunity updates for ACME Corporation client."
- ✅ Attachment present: PDF file
- ✅ Email is plain text (no HTML template)

**Status**: ⬜

---

### TC-011: Multiple Submissions
**Objective**: Verify user can submit multiple times for same opportunity

**Steps**:
1. Submit update with Amount = $150,000, Employees = 750
2. Wait for success
3. Submit again with Amount = $175,000, Employees = 800

**Expected Results**:
- ✅ Both submissions succeed
- ✅ Two separate emails sent
- ✅ Final values: Amount = $175,000, Employees = 800

**Status**: ⬜

---

### TC-012: Special Characters in Opportunity Name
**Objective**: Verify handling of special characters in PDF filename

**Pre-conditions**:
- Create Opportunity with name: "Q1/Q2 Deal - 2026 (ACME)"

**Steps**:
1. Submit update

**Expected Results**:
- ✅ PDF filename sanitized: "Opportunity_Update_Q1_Q2_Deal___2026__ACME_.pdf"
- ✅ PDF header shows original name with special chars

**Status**: ⬜

---

### TC-013: Null Amount Value
**Objective**: Verify system handles null amount

**Steps**:
1. Open modal
2. Clear Amount field (if possible via browser console)
3. Submit

**Expected Results**:
- ✅ Either validation prevents null OR
- ✅ System accepts null and updates Opportunity.Amount to null

**Status**: ⬜

---

### TC-014: Concurrent User Testing
**Objective**: Verify no conflicts with multiple users

**Steps**:
1. User A opens modal for Opportunity X
2. User B opens modal for Opportunity Y (different opp)
3. Both submit simultaneously

**Expected Results**:
- ✅ Both updates succeed
- ✅ No record locking issues
- ✅ Two separate emails sent

**Status**: ⬜

---

### TC-015: Profile Permission Testing
**Objective**: Verify only authorized users can update

**Steps**:
1. Login as Sales User (should have access)
2. Verify button visible and functional
3. Login as Standard User without Opportunity edit access
4. Verify appropriate behavior

**Expected Results**:
- ✅ Sales User: Full access
- ✅ Non-sales User: Either button hidden OR error on submit

**Status**: ⬜

---

## Performance Test Cases

### TC-016: Page Load Performance
**Objective**: Verify LWC loads quickly

**Steps**:
1. Navigate to Opportunity record page
2. Measure time to button render

**Expected Results**:
- ✅ Button visible within 2 seconds

**Status**: ⬜

---

### TC-017: Modal Data Load Performance
**Objective**: Verify data retrieval is fast

**Steps**:
1. Click button
2. Measure time to modal fully populated

**Expected Results**:
- ✅ Modal data loaded within 1 second

**Status**: ⬜

---

### TC-018: Submission Performance
**Objective**: Verify end-to-end submission completes quickly

**Steps**:
1. Submit form
2. Measure time to success message

**Expected Results**:
- ✅ Success message within 5 seconds (includes DML, PDF, email)

**Status**: ⬜

---

## Negative Test Cases

### TC-019: Invalid Opportunity ID
**Objective**: Verify graceful error handling for corrupted record ID

**Steps**:
1. Manually invoke Apex with invalid ID (via Developer Console)

**Expected Results**:
- ✅ AuraHandledException thrown
- ✅ Error message logged

**Status**: ⬜

---

### TC-020: Email Delivery Failure Simulation
**Objective**: Verify behavior if email fails (though unlikely)

**Steps**:
1. Temporarily set invalid email address in code
2. Deploy and test

**Expected Results**:
- ✅ DML operations still complete (records updated)
- ✅ Email error logged but doesn't block transaction

**Status**: ⬜

---

## Regression Test Cases

### TC-021: Existing Opportunity Functionality
**Objective**: Verify new component doesn't break standard Opportunity features

**Steps**:
1. Create new Opportunity
2. Edit standard fields
3. Close Opportunity
4. Delete Opportunity

**Expected Results**:
- ✅ All standard operations work normally

**Status**: ⬜

---

### TC-022: Existing Account Functionality
**Objective**: Verify Account updates don't break related functionality

**Steps**:
1. Update Account via standard UI
2. Verify NumberOfEmployees validation works outside component
3. Test Account deletion prevention (if Opportunities exist)

**Expected Results**:
- ✅ Validation rule works universally
- ✅ No regressions in Account behavior

**Status**: ⬜

---

## Test Execution Summary

| Category | Total | Pass | Fail | Not Executed |
|----------|-------|------|------|--------------||
| Unit Tests | 11 | - | - | - |
| Functional | 15 | - | - | - |
| Performance | 3 | - | - | - |
| Negative | 2 | - | - | - |
| Regression | 2 | - | - | - |
| **TOTAL** | **33** | **0** | **0** | **33** |

---

## Test Data Requirements

### Minimum Test Data
- 3 Accounts with varying NumberOfEmployees (5, 500, 150000)
- 5 Opportunities in different stages
- 1 Sales User profile
- 1 Standard User profile (for permission testing)

### Test Email Account
- *****@gmail.com must be accessible for verification

---

## Known Limitations / Assumptions

1. **Email Deliverability**: Sandbox emails may be restricted; use Email Log for verification
2. **PDF Preview**: Manual PDF verification required in test cases TC-009
3. **Visualforce**: Requires Visualforce enabled in org (standard for most editions)
4. **Validation Rule**: Applies globally to Account object (not just this component)

---

## Test Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------||
| Developer | AI Platform Expert | 2026-02-17 | _________ |
| QA Lead | [TBD] | _________ | _________ |
| Business Owner | [TBD] | _________ | _________ |

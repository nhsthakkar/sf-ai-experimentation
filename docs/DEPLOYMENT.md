# Deployment Instructions: Opportunity Update Solution

## Prerequisites
- Salesforce CLI (sf) installed
- Git repository initialized
- Connected to target org via `sf org login web`

---

## Step 1: Validate Repository Structure

Ensure your repository has this structure:

```
force-app/
├── main/
│   └── default/
│       ├── classes/
│       │   ├── OpportunityUpdateController.cls
│       │   ├── OpportunityUpdateController.cls-meta.xml
│       │   ├── OpportunityUpdateController_Test.cls
│       │   ├── OpportunityUpdateController_Test.cls-meta.xml
│       │   ├── OpportunityUpdatePDFController.cls
│       │   └── OpportunityUpdatePDFController.cls-meta.xml
│       ├── lwc/
│       │   └── opportunityUpdateForm/
│       │       ├── opportunityUpdateForm.html
│       │       ├── opportunityUpdateForm.js
│       │       ├── opportunityUpdateForm.js-meta.xml
│       │       └── opportunityUpdateForm.css
│       ├── pages/
│       │   ├── OpportunityUpdatePDF.page
│       │   └── OpportunityUpdatePDF.page-meta.xml
│       └── objects/
│           └── Account/
│               └── validationRules/
│                   └── Number_of_Employees_Range.validationRule-meta.xml
manifest/
└── package.xml
```

---

## Step 2: Deploy Validation Rule

```bash
sf project deploy start --source-path force-app/main/default/objects/Account/validationRules/ --target-org YOUR_ORG_ALIAS
```

**Verify**: 
- Login to Salesforce → Setup → Object Manager → Account → Validation Rules
- Confirm "Number_of_Employees_Range" is Active

---

## Step 3: Deploy Apex Classes

```bash
sf project deploy start --source-path force-app/main/default/classes/ --target-org YOUR_ORG_ALIAS
```

**Verify**:
- Setup → Apex Classes
- Confirm all 3 classes deployed (OpportunityUpdateController, OpportunityUpdatePDFController, OpportunityUpdateController_Test)

---

## Step 4: Deploy Visualforce Page

```bash
sf project deploy start --source-path force-app/main/default/pages/ --target-org YOUR_ORG_ALIAS
```

**Verify**:
- Setup → Visualforce Pages
- Confirm "OpportunityUpdatePDF" exists

---

## Step 5: Deploy Lightning Web Component

```bash
sf project deploy start --source-path force-app/main/default/lwc/opportunityUpdateForm/ --target-org YOUR_ORG_ALIAS
```

**Verify**:
- Setup → Lightning Components
- Search for "opportunityUpdateForm"

---

## Step 6: Run Apex Tests

```bash
sf apex run test --class-names OpportunityUpdateController_Test --result-format human --code-coverage --target-org YOUR_ORG_ALIAS
```

**Expected Output**:
- All 11 tests pass
- Code coverage: 100% for OpportunityUpdateController
- Code coverage: 100% for OpportunityUpdatePDFController

---

## Step 7: Add Component to Opportunity Page Layout

### Manual Configuration Required:

1. **Navigate to Opportunity Record Page**:
   - Setup → Object Manager → Opportunity
   - Lightning Record Pages → Select your active page (or create new)

2. **Edit Page in Lightning App Builder**:
   - Click "Edit Page"
   - From Components panel (left), drag **opportunityUpdateForm** to desired location
   - Recommended: Place in right sidebar or above Related Lists

3. **Save and Activate**:
   - Click "Save"
   - Click "Activation"
   - Assign to appropriate profiles (e.g., Sales User)
   - Set as org default or assign to specific app

---

## Step 8: Grant Permissions

### Option A: Permission Set (Recommended)

1. Setup → Permission Sets → New
2. Name: "Opportunity Update Access"
3. Assign Object Permissions:
   - Opportunity: Read, Edit
   - Account: Read, Edit
4. Assign Field Permissions:
   - Opportunity.Amount: Read, Edit
   - Account.NumberOfEmployees: Read, Edit
5. Assign Apex Class Access:
   - OpportunityUpdateController
   - OpportunityUpdatePDFController
6. Assign Visualforce Page Access:
   - OpportunityUpdatePDF
7. Assign to Sales Users

### Option B: Modify Existing Profile

1. Setup → Profiles → [Your Sales Profile]
2. Enable same permissions as above

---

## Step 9: Verification Testing

Run through Quick Smoke Test:

1. Login as Sales User
2. Navigate to any Opportunity
3. Verify "Submit for Onboarding" button visible
4. Click button → Modal opens with current values
5. Update Amount and Number of Employees (valid values)
6. Submit
7. Verify success message
8. Check email inbox for nhsthakkar@gmail.com
9. Verify PDF attachment

---

## Step 10: Production Deployment (if applicable)

### For Sandbox → Production:

```bash
# Create deployment package
sf project deploy start --source-path force-app/ --target-org PRODUCTION_ALIAS --test-level RunSpecifiedTests --tests OpportunityUpdateController_Test --dry-run

# After dry-run success, deploy for real
sf project deploy start --source-path force-app/ --target-org PRODUCTION_ALIAS --test-level RunSpecifiedTests --tests OpportunityUpdateController_Test
```

---

## Rollback Procedure

If issues arise:

```bash
# Delete LWC
sf project deploy start --metadata "LightningComponentBundle:opportunityUpdateForm" --target-org YOUR_ORG_ALIAS --purge-on-delete

# Delete Apex Classes
sf project deploy start --metadata "ApexClass:OpportunityUpdateController,ApexClass:OpportunityUpdateController_Test,ApexClass:OpportunityUpdatePDFController" --target-org YOUR_ORG_ALIAS --purge-on-delete

# Delete Visualforce Page
sf project deploy start --metadata "ApexPage:OpportunityUpdatePDF" --target-org YOUR_ORG_ALIAS --purge-on-delete

# Deactivate Validation Rule (manual)
```

---

## Troubleshooting

### Issue: Tests Fail Due to Email
**Solution**: Tests mock emails in Test context; verify `Test.isRunningTest()` checks are present

### Issue: PDF Not Generating
**Solution**: 
- Verify Visualforce is enabled
- Check `OpportunityUpdatePDF.page` is deployed
- Inspect Debug Logs for errors

### Issue: Button Not Visible
**Solution**:
- Verify component added to Lightning Record Page
- Check user profile has access to Lightning page
- Confirm user has Edit access to Opportunity/Account

### Issue: Validation Error in Production
**Solution**:
- Verify validation rule is Active
- Test with valid range (10-100,000)
- Check field-level security

---

## Post-Deployment Checklist

- [ ] All Apex classes deployed
- [ ] Validation rule active
- [ ] Visualforce page accessible
- [ ] LWC added to Opportunity page layout
- [ ] Permissions assigned to users
- [ ] Unit tests pass (100% coverage)
- [ ] Functional testing completed (TC-001 minimum)
- [ ] Email verification successful
- [ ] PDF format verified
- [ ] Documentation updated

---

## Support Contacts

- **Developer**: AI Salesforce Platform Expert
- **Salesforce Admin**: [Admin Name/Email]
- **Business Owner**: Nimish (nhsthakkar@gmail.com)

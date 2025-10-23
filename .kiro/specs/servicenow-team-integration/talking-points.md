# Quick Talking Points - ServiceNow-TEAM Integration

## 🎤 Opening (30 seconds)

> "We're building a bidirectional integration between ServiceNow and AWS IAM Identity Center TEAM for Waters Corporation. This gives their cloud engineering team automated, time-bound access to production accounts through their existing ServiceNow ITSM platform. **We need to demo this to the customer mid-next week.**"

---

## 💡 Why This Matters (1 minute)

**For Waters Corporation:**
- They're a pharma instruments company (liquid chromatography)
- Need least privilege access to production AWS accounts
- Regulatory compliance requires complete audit trails
- Want to use ServiceNow as their ITSM/SIM trigger
- Cloud engineering team isn't familiar with Identity Center yet

**For Us:**
- Demonstrates TEAM's enterprise integration capabilities
- Reusable pattern for other ServiceNow customers
- CloudFormation packaging makes it easy to deploy

---

## ⏰ Timeline Reality Check (1 minute)

**8 weeks is aggressive but achievable because:**
- ✅ No frontend development (CLI testing only)
- ✅ CloudFormation deployment (infrastructure as code)
- ✅ Focused MVP scope (no custom UI, no advanced reporting)
- ✅ Leveraging existing TEAM APIs

**Critical milestone:**
- 🚨 **Customer demo in 3 days** (mid-next week)
- Need working POC: ServiceNow → TEAM request creation

---

## 💰 Budget Justification (1 minute)

**$72K-$96K for 8 weeks:**
- 400 hours of engineering effort
- 3-4 engineers (AWS, ServiceNow, DevOps)
- Includes POC, full integration, CloudFormation packaging
- 10% contingency buffer

**Why this is reasonable:**
- Comparable projects: $100K-$150K for 12 weeks
- We're saving time with CLI-only testing
- CloudFormation reduces deployment complexity

---

## 🎯 What We're Delivering (1 minute)

**Week 1:** Architecture + Customer POC demo  
**Weeks 2-4:** ServiceNow → TEAM integration  
**Weeks 5-6:** Bidirectional sync + approvals  
**Week 7:** CloudFormation templates  
**Week 8:** Production go-live  

**MVP Features:**
- Request creation from ServiceNow
- Approval workflow sync
- Session status tracking
- Audit logging
- Easy deployment via CloudFormation

---

## ⚠️ Risk Management (1 minute)

**Top 3 Risks:**

1. **Customer demo in 3 days**
   - Mitigation: Build POC first, full features later
   - Need team assigned TODAY

2. **ServiceNow access delay**
   - Mitigation: Request access TODAY from Waters
   - Can use mock API if delayed

3. **Scope creep**
   - Mitigation: Lock MVP scope, document future enhancements
   - Customer is "open to modifications" = risk!

---

## ✅ What We Need Today (1 minute)

**5 Critical Decisions:**

1. **Budget approval:** $72K-$96K?
2. **Team assignments:** Who are the 3-4 engineers?
3. **Timeline approval:** 8 weeks acceptable?
4. **Scope agreement:** MVP features only?
5. **Demo presenter:** Who presents to Waters?

**3 Immediate Actions:**

1. Request ServiceNow dev instance access from Waters
2. Obtain TEAM API credentials
3. Schedule team kickoff for tomorrow

---

## 🎬 Closing (30 seconds)

> "This is a tight timeline with a customer demo in 3 days, but it's achievable with the right team. We need budget approval and team assignments today so we can start building the POC tomorrow. Waters Corporation is expecting an update mid-next week, and we want to show them a working integration."

---

## 🤔 Anticipated Questions & Answers

**Q: Why 8 weeks instead of 12?**
> A: No frontend development (CLI testing only) and CloudFormation deployment reduces complexity. We're focused on core integration features.

**Q: What if we can't get ServiceNow access by tomorrow?**
> A: We'll build against a mock ServiceNow API for the POC, then integrate with real instance once access is granted.

**Q: What happens after the customer demo?**
> A: If they approve, we continue with full development. If they want changes, we adjust scope and timeline.

**Q: Can we do this with fewer engineers?**
> A: Possible but risky. 3-4 engineers gives us redundancy and allows parallel workstreams (ServiceNow + TEAM + DevOps).

**Q: What if the customer wants more features?**
> A: We document as future enhancements. MVP scope is locked to hit 8-week timeline.

**Q: How do we test without a frontend?**
> A: CLI test harness that simulates ServiceNow API calls. Faster to build and test than a UI.

---

## 📊 Success Metrics to Emphasize

- ✅ Customer demo mid-next week (POC working)
- ✅ <30 second request processing time
- ✅ 99.9% uptime
- ✅ 100% audit trail completeness
- ✅ Easy CloudFormation deployment for Waters team

---

## 🎯 Call to Action

**By end of this meeting:**
- [ ] Budget approved
- [ ] Team assigned
- [ ] ServiceNow access requested
- [ ] TEAM API credentials obtained
- [ ] Customer demo scheduled

**By tomorrow:**
- [ ] Team kickoff meeting
- [ ] POC development started
- [ ] Architecture design in progress

**By Day 3-4:**
- [ ] **Customer demo with Waters Corporation**

---

**Remember:** This is about enabling Waters Corporation's cloud engineering team to securely access production accounts through their familiar ServiceNow interface. We're not just building an integration—we're solving a real business problem for a pharma company that needs regulatory compliance.

return function()
	local TrustAndSafety = script.Parent.Parent
	local OpenReportDialog = require(TrustAndSafety.Actions.OpenReportDialog)
	local CloseReportDialog = require(TrustAndSafety.Actions.CloseReportDialog)
	local OpenReportSentDialog = require(TrustAndSafety.Actions.OpenReportSentDialog)
	local CloseReportSentDialog = require(TrustAndSafety.Actions.CloseReportSentDialog)
	local report = require(script.Parent.report)

	describe("Initial state", function()
		it("should be closed by default", function()
			local defaultState = report(nil, {})
			expect(defaultState.dialogOpen).to.equal(false)
			expect(defaultState.isReportSentOpen).to.equal(false)
		end)
	end)

	describe("OpenReportDialog", function()
		it("should set the report dialog open for a user", function()
			local oldState = report(nil, {})
			local newState = report(oldState, OpenReportDialog(261, "Shedletsky"))
			expect(oldState).to.never.equal(newState)
			expect(newState.dialogOpen).to.equal(true)
			expect(newState.userId).to.equal(261)
			expect(newState.userName).to.equal("Shedletsky")
		end)

		it("should set the report dialog open for a game", function()
			local oldState = report(nil, {})
			oldState = report(oldState, OpenReportDialog(261, "Shedletsky"))
			local newState = report(oldState, OpenReportDialog())
			expect(oldState).to.never.equal(newState)
			expect(newState.dialogOpen).to.equal(true)
			expect(newState.userId).to.equal(nil)
			expect(newState.userName).to.equal(nil)
		end)
	end)

	describe("CloseReportDialog", function()
		it("should set the report dialog closed", function()
			local oldState = report(nil, {})
			oldState = report(oldState, OpenReportDialog(261, "Shedletsky"))
			local newState = report(oldState, CloseReportDialog())
			expect(oldState).to.never.equal(newState)
			expect(newState.dialogOpen).to.equal(false)
		end)
	end)

	describe("ReportSentDialog", function()
		it("should open", function()
			local oldState = report(nil, {})
			local newState = report(oldState, OpenReportSentDialog(nil, nil))
			expect(oldState).to.never.equal(newState)
			expect(newState.isReportSentOpen).to.equal(true)
		end)

		it("should close", function()
			local oldState = report(nil, {})
			oldState = report(oldState, OpenReportSentDialog(nil, nil))
			
			local newState = report(oldState, CloseReportSentDialog())
			expect(oldState).to.never.equal(newState)
			expect(newState.isReportSentOpen).to.equal(false)
		end)
	end)
end
local Flow = require(script.Parent.Parent.GameTable.UploadDownloadFlow)
local RecursiveEquals = require(script.Parent.RecursiveEquals)
local Promise = require(script.Parent.Parent.Promise)

local MockPatch = {"I'm a patch"}

local function NeverReaches(patchInfo)
	assert(false, "control never reaches this point")
end

local MockLocalizationTable = {"I'm a LocalizationTable"}

return function()
	it("traverses successful download", function()
		local currentState = {"NOSTATE"}
		local currentMessage = {"NOMESSAGE"}

		local section = {
			setState = function(_, state)
				currentState = state
			end,
		}

		local flow

		local function DownloadGameTable()
			return Promise.new(function(resolve, reject)
				expect(reject).to.be.a("function")
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(currentMessage).to.equal("Downloading table...")

				-- Table data download succeeds
				resolve(MockLocalizationTable)
			end)
		end

		local function SaveCSV(localizationTable)
			return Promise.new(function(resolve, reject)
				expect(localizationTable).to.equal(MockLocalizationTable)
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(currentMessage).to.equal("Select CSV file...")

				-- User selects a destination on their harddrive, and file write succeeds
				resolve()
			end)
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			DownloadGameTable = DownloadGameTable,
			SaveCSV = SaveCSV,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		expect(flow._busy).to.equal(false)
		flow:OnDownload():andThen(
			function()
				expect(flow._busy).to.equal(false)
				expect(currentMessage).to.equal("Table written to file")
				assert(RecursiveEquals(currentState, {
					NonInteractive = false,
					ShowProgressIndicator = false,
				}))
			end
		)
	end)

	it("traverses successful download with asynchronous callbacks", function()
		local currentState = {"NOSTATE"}
		local currentMessage = {"NOMESSAGE"}

		local section = {
			setState = function(_, state)
				currentState = state
			end,
		}

		local flow

		local function DownloadGameTable()
			return Promise.new(function(resolve, reject)
				expect(reject).to.be.a("function")
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(currentMessage).to.equal("Downloading table...")

				-- Table data download succeeds
				spawn(function()
					resolve({"I'm a localization table"})
				end)
			end)
		end

		local function SaveCSV(localizationTable)
			return Promise.new(function(resolve, reject)
				expect(localizationTable).never.to.equal(nil)
				expect(resolve).to.be.a("function")
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(currentMessage).to.equal("Select CSV file...")

				-- User selects a destination on their harddrive, and file write succeeds
				spawn(function()
					resolve()

					expect(flow._busy).to.equal(false)
					expect(currentMessage).to.equal("Table written to file")
					assert(RecursiveEquals(currentState, {
						NonInteractive = false,
						ShowProgressIndicator = false,
					}))
				end)
			end)
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			DownloadGameTable = DownloadGameTable,
			SaveCSV = SaveCSV,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		flow:OnDownload()
	end)

	it("navigates unsuccesful download", function()
		local currentState = {"NOSTATE"}
		local currentMessage = {"NOMESSAGE"}

		local section = {
			setState = function(_, state)
				currentState = state
			end,
		}

		local flow

		local function DownloadGameTable()
			return Promise.new(function(resolve, reject)
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(resolve).to.be.a("function")
				reject("Download failed")
			end)
		end

		local function SaveCSV()
			NeverReaches()
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			DownloadGameTable = DownloadGameTable,
			SaveCSV = SaveCSV,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		flow:OnDownload():andThen(
			NeverReaches,
			function(errorMessage)
				expect(flow._busy).to.equal(false)
				expect(errorMessage).to.equal("Download failed")
				expect(currentMessage).to.equal("Download failed")
				assert(RecursiveEquals(currentState, {
					NonInteractive = false,
					ShowProgressIndicator = false,
				}))
			end
		)
	end)

	it("navigates download where save failed", function()
		local currentState = {"NOSTATE"}
		local currentMessage = {"NOMESSAGE"}

		local section = {
			setState = function(_, state)
				currentState = state
			end,
		}

		local flow

		local function DownloadGameTable()
			return Promise.new(function(resolve, reject)
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				resolve({"I'm a LocalizationTable"})
			end)
		end

		local function SaveCSV(localizationTable)
			return Promise.new(function(resolve, reject)
				expect(localizationTable).to.be.a("table")
				expect(resolve).to.be.a("function")
				reject("Download canceled")
			end)
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			DownloadGameTable = DownloadGameTable,
			SaveCSV = SaveCSV,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		flow:OnDownload():andThen(
			NeverReaches,
			function(errorMessage)
				expect(flow._busy).to.equal(false)
				expect(errorMessage).to.equal("Download canceled")
				expect(currentMessage).to.equal("Download canceled")
				assert(RecursiveEquals(currentState, {
					NonInteractive = false,
					ShowProgressIndicator = false,
				}))
			end
		)
	end)

	it("traverses successful upload", function()
		local currentState = {"NOSTATE"}
		local currentMessage = {"NOMESSAGE"}
		local uploadedPatch = {"NOUPLOAD"}

		local section = {
			_busy = false,
			setState = function(self, state)
				currentState = state
			end
		}

		local flow

		local function OpenCSV()
			return Promise.new(function(resolve, reject)
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(currentMessage).to.equal("Open CSV file...")

				-- User selects a proper csv and it loads into a Localization Table
				resolve(MockLocalizationTable)
			end)
		end

		local function ComputePatch(localizationTable)
			return Promise.new(function(resolve, reject)
				expect(localizationTable).to.equal(MockLocalizationTable)
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(currentMessage).to.equal("Computing patch...")

				-- Patch computes successfully (which means the download succeeds)
				resolve({
					patch = MockPatch,
				})
			end)
		end

		local MockRenderFunction = function() end

		local MakeRenderDialogContent = function()
			return MockRenderFunction
		end

		local function ShowDialog(title, sizeX, sizeY, renderContent)
			return Promise.new(function(resolve, reject)
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(currentMessage).to.equal("Confirm upload...")
				expect(MockRenderFunction).to.equal(MockRenderFunction)

				-- User hits "okay"
				resolve()
			end)
		end

		local function UploadPatch(patchInfo)
			return Promise.new(function(resolve, reject)
				expect(flow._busy).to.equal(true)
				expect(currentState.NonInteractive).to.equal(true)
				expect(currentMessage).to.equal("Uploading patch...")
				expect(patchInfo.patch).to.equal(MockPatch)
				uploadedPatch = patchInfo.patch

				-- The internet is working, and patch upload succeeds
				resolve()
			end)
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			OpenCSV = OpenCSV,
			ComputePatch = ComputePatch,
			ShowDialog = ShowDialog,
			UploadPatch = UploadPatch,

			MakeRenderDialogContent = MakeRenderDialogContent,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		flow:OnUpload():andThen(
			function()
				expect(section._busy).to.equal(false)
				expect(currentMessage).to.equal("Upload complete")
				expect(uploadedPatch).to.equal(MockPatch)
				assert(RecursiveEquals(currentState, {
					NonInteractive = false,
					ShowProgressIndicator = false,
				}))
			end)
	end)

	it("navigates CSV file not provided", function()
		local currentState = {"WRONGSTATE"}
		local currentMessage = {"WRONGMESSAGE"}
		local mockDefaultUpload = {"WRONGUPLOAD"}
		local uploadedPatch = mockDefaultUpload

		local section = {
			_busy = false,
			setState = function(self, state)
				currentState = state
			end,
		}

		local flow

		local function OpenCSV()
			return Promise.reject()
		end

		local function ComputePatch(localizationTable)
			NeverReaches()
		end

		local function ShowDialog(title, sizeX, sizeY, renderContent)
			NeverReaches()
		end

		local function UploadPatch(patchInfo, resolve, reject)
			NeverReaches()
		end

		local MockRenderFunction = function() end

		local MakeRenderDialogContent = function()
			return MockRenderFunction
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			OpenCSV = OpenCSV,
			ComputePatch = ComputePatch,
			ShowDialog = ShowDialog,
			UploadPatch = UploadPatch,

			MakeRenderDialogContent = MakeRenderDialogContent,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		flow:OnUpload():andThen(
			NeverReaches,
			function(errorMessage)
				expect(section._busy).to.equal(false)
				expect(errorMessage).to.equal("CSV file not provided")
				expect(currentMessage).to.equal("CSV file not provided")
				expect(currentState.NonInteractive).to.equal(false)
				expect(uploadedPatch).to.equal(mockDefaultUpload)
			end
		)
	end)


	it("navigates compute patch failed", function()
		local currentState = {"WRONGSTATE"}
		local currentMessage = {"WRONGMESSAGE"}
		local uploadedPatch = {"WRONGUPLOAD"}

		local section = {
			_busy = false,
			setState = function(self, state)
				currentState = state
			end,
		}

		local flow

		local function OpenCSV()
			return Promise.new(function(resolve, reject)
				-- User selects a proper csv and it loads into a Localization Table
				resolve( {"I'm a LocalizationTable"} )
			end)
		end

		local function ComputePatch(localizationTable)
				-- Patch compute fails
			return Promise.reject("Patch compute failed, probably because the download failed")
		end

		local function ShowDialog(title, sizeX, sizeY, renderContent)
			NeverReaches()
		end

		local function UploadPatch(patchInfo, resolve, reject)
			NeverReaches()
		end

		local MockRenderFunction = function() end

		local MakeRenderDialogContent = function()
			return MockRenderFunction
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			OpenCSV = OpenCSV,
			ComputePatch = ComputePatch,
			ShowDialog = ShowDialog,
			UploadPatch = UploadPatch,

			MakeRenderDialogContent = MakeRenderDialogContent,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		flow:OnUpload():andThen(
			NeverReaches,
			function(errorMessage)
				expect(section._busy).to.equal(false)
				expect(errorMessage).to.equal("Compute patch failed")
				expect(currentMessage).to.equal("Compute patch failed")
				assert(RecursiveEquals(currentState, {
					NonInteractive = false,
					ShowProgressIndicator = false,
				}))
				expect(uploadedPatch).never.to.equal(MockPatch)
			end)
	end)

	it("navigates user canceled", function()
		local currentState = {"NOSTATE"}
		local currentMessage = {"NOMESSAGE"}
		local uploadedPatch = {"NOUPLOAD"}

		local section = {
			_busy = false,
			setState = function(self, state)
				currentState = state
			end,
		}

		local flow

		local function OpenCSV()
			return Promise.new(function(resolve, reject)
				-- User selects a proper csv and it loads into a Localization Table
				resolve( {"I'm a LocalizationTable"} )
			end)
		end

		local function ComputePatch(localizationTable)
			return Promise.new(function(resolve, reject)
				-- Patch computes successfully (which means the download succeeds)
				local patchInfo = {
					patch = MockPatch,
				}

				resolve(patchInfo)
			end)
		end

		local function ShowDialog(title, sizeX, sizeY, renderContent)
			-- User hits "cancel"
			return Promise.reject()
		end

		local function UploadPatch(patchInfo, resolve, reject)
			assert(false)
		end

		local MockRenderFunction = function() end

		local MakeRenderDialogContent = function()
			return MockRenderFunction
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			OpenCSV = OpenCSV,
			ComputePatch = ComputePatch,
			ShowDialog = ShowDialog,
			UploadPatch = UploadPatch,

			MakeRenderDialogContent = MakeRenderDialogContent,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		flow:OnUpload():andThen(
			NeverReaches,
			function(errorMessage)
				expect(section._busy).to.equal(false)
				expect(errorMessage).to.equal("Upload canceled")
				expect(currentMessage).to.equal("Upload canceled")
				assert(RecursiveEquals(currentState, {
					NonInteractive = false,
					ShowProgressIndicator = false,
				}))
				expect(uploadedPatch).never.to.equal(MockPatch)
			end
		)
	end)

	it("navigates upload failed", function()
		local currentState = {"NOSTATE"}
		local currentMessage = {"NOMESSAGE"}
		local mockDefaultUpload = {"NOUPLOAD"}
		local uploadedPatch = mockDefaultUpload

		local section = {
			_busy = false,
			setState = function(self, state)
				currentState = state
			end,
		}

		local flow

		local function OpenCSV()
			return Promise.new(function(resolve, reject)
				-- User selects a proper csv and it loads into a Localization Table
				resolve( {"I'm a LocalizationTable"} )
			end)
		end

		local function ComputePatch(localizationTable)
			return Promise.resolve({
				patch = MockPatch,
			})
		end

		local function ShowDialog(title, sizeX, sizeY, renderContent)
			return Promise.new(function(resolve, reject)
			-- User hits "okay"
				expect(title).to.be.a("string")
				expect(sizeX).to.be.a("number")
				expect(sizeY).to.be.a("number")
				expect(renderContent).to.be.a("function")

				resolve()
			end)
		end

		local function UploadPatch(patchInfo)
			return Promise.reject("Upload failed")
		end

		local MockRenderFunction = function() end

		local MakeRenderDialogContent = function()
			return MockRenderFunction
		end

		flow = Flow.new({
			SetMessage = function(message)
				currentMessage = message
			end,

			OpenCSV = OpenCSV,
			ComputePatch = ComputePatch,
			ShowDialog = ShowDialog,
			UploadPatch = UploadPatch,

			MakeRenderDialogContent = MakeRenderDialogContent,

			UpdateBusyMode = function(nonInteractive, showProgressIndicator)
				section:setState({
					NonInteractive = nonInteractive,
					ShowProgressIndicator = showProgressIndicator,
				})
			end,
		})

		flow:OnUpload():andThen(
			NeverReaches,
			function(errorMessage)
				expect(section._busy).to.equal(false)
				expect(errorMessage).to.equal("Upload failed")
				expect(currentMessage).to.equal("Upload failed")
				assert(RecursiveEquals(currentState, {
					NonInteractive = false,
					ShowProgressIndicator = false,
				}))
				expect(uploadedPatch).to.equal(mockDefaultUpload)
			end)
	end)
end

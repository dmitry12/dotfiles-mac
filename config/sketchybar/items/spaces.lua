local appearance = require("appearance")
local app_icons = require("helpers.app_icons")
local sbar = require("sketchybar")

local workspace_names = {
	["1"] = "🌍",
	["2"] = "💻",
	["3"] = "💾",
	["4"] = "💬",
	["5"] = "👹",
	["6"] = "👾",
	["7"] = "⺟",
	["8"] = "⺟",
	["9"] = "🛰️",
	["Q"] = "📒",
	["C"] = "🗿",
}

local workspace_role = {
	["1"] = "peripheral",
	["2"] = "active",
	["3"] = "focal",
	["4"] = "peripheral",
	["5"] = "active",
	["6"] = "focal",
	["7"] = "focal",
	["8"] = "active",
	["9"] = "peripheral",
}

local query_workspaces =
	"aerospace list-workspaces --all --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' --json"

-- Root is used to handle event subscriptions
local root = sbar.add("item", { drawing = false })
local workspaces = {}

local function withWindows(f)
	local open_windows = {}
	-- Include the window ID in the query so we can track unique windows
	local get_windows = "aerospace list-windows --monitor all --format '%{workspace}%{app-name}%{window-id}' --json"
	local query_visible_workspaces =
		"aerospace list-workspaces --visible --monitor all --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' --json"
	local get_focus_workspaces = "aerospace list-workspaces --focused"
	sbar.exec(get_windows, function(workspace_and_windows)
		-- Use a set to track unique window IDs
		local processed_windows = {}

		for _, entry in ipairs(workspace_and_windows) do
			local workspace_index = entry.workspace
			local app = entry["app-name"]
			local window_id = entry["window-id"]

			-- Only process each window ID once
			if not processed_windows[window_id] then
				processed_windows[window_id] = true

				if open_windows[workspace_index] == nil then
					open_windows[workspace_index] = {}
				end

				-- Check if this app is already in the list for this workspace
				local app_exists = false
				for _, existing_app in ipairs(open_windows[workspace_index]) do
					if existing_app == app then
						app_exists = true
						break
					end
				end

				-- Only add the app if it's not already in the list
				if not app_exists then
					table.insert(open_windows[workspace_index], app)
				end
			end
		end

		sbar.exec(get_focus_workspaces, function(focused_workspaces)
			sbar.exec(query_visible_workspaces, function(visible_workspaces)
				local args = {
					open_windows = open_windows,
					focused_workspaces = focused_workspaces,
					visible_workspaces = visible_workspaces,
				}
				f(args)
			end)
		end)
	end)
end

local function updateWindow(workspace_index, args)
	local open_windows = args.open_windows[workspace_index]
	local focused_workspaces = args.focused_workspaces
	local visible_workspaces = args.visible_workspaces

	if open_windows == nil then
		open_windows = {}
	end

	local icon_line = ""
	local no_app = true
	for _, open_window in ipairs(open_windows) do
		no_app = false
		local app = open_window
		local lookup = app_icons[app]
		local icon = ((lookup == nil) and app_icons["Default"] or lookup)
		icon_line = icon_line .. "" .. icon
	end

	sbar.animate("tanh", 10, function()
		for _, visible_workspace in ipairs(visible_workspaces) do
			if no_app and workspace_index == visible_workspace["workspace"] then
				local monitor_id = visible_workspace["monitor-appkit-nsscreen-screens-id"]
				icon_line = " —"
				workspaces[workspace_index]:set({
					drawing = true,
					["label.string"] = icon_line,
					display = monitor_id,
				})
				return
			end
		end
		if no_app and workspace_index ~= focused_workspaces then
			workspaces[workspace_index]:set({
				drawing = false,
			})
			return
		end
		if no_app and workspace_index == focused_workspaces then
			icon_line = " —"
			workspaces[workspace_index]:set({
				drawing = true,
				["label.string"] = icon_line,
			})
		end

		workspaces[workspace_index]:set({
			drawing = true,
			["label.string"] = icon_line,
		})
	end)
end

local function updateWindows()
	withWindows(function(args)
		for workspace_index, _ in pairs(workspaces) do
			updateWindow(workspace_index, args)
		end
	end)
end

local function updateWorkspaceMonitor()
	local workspace_monitor = {}
	sbar.exec(query_workspaces, function(workspaces_and_monitors)
		for _, entry in ipairs(workspaces_and_monitors) do
			local space_index = entry.workspace
			local monitor_id = math.floor(entry["monitor-appkit-nsscreen-screens-id"])
			workspace_monitor[space_index] = monitor_id
		end
		for workspace_index, _ in pairs(workspaces) do
			workspaces[workspace_index]:set({
				display = workspace_monitor[workspace_index],
			})
		end
	end)
end

sbar.exec(query_workspaces, function(workspaces_and_monitors)
	for _, entry in ipairs(workspaces_and_monitors) do
		local workspace_index = entry.workspace
		local role = appearance.roles[workspace_role[workspace_index]]
		local style = appearance.styles.workspace

		local workspace = sbar.add("item", "workspace." .. workspace_index, {
			background = {
				color = role.color,
				border_color = role.color,
				border_width = 1,
				corner_radius = 6,
				drawing = true,
			},
			click_script = "aerospace workspace " .. workspace_index,
			drawing = false,
			icon = {
				color = role.icon_color,
				highlight_color = role.icon_highlight_color,
				font = style.icon.font,
				padding_left = style.icon.padding_left,
				padding_right = style.icon.padding_right,
				drawing = true,
				string = workspace_index
					.. (workspace_names[workspace_index] and ": " .. workspace_names[workspace_index] or ""),
			},
			label = {
				color = style.label.color,
				highlight_color = style.label.highlight_color,
				font = style.label.font,
				padding_left = style.label.padding_left,
				padding_right = style.label.padding_right,
				y_offset = style.label.y_offset,
				drawing = true,
			},
		})

		workspaces[workspace_index] = workspace

		workspace:subscribe("aerospace_workspace_change", function(env)
			local focused_workspace = env.FOCUSED_WORKSPACE
			local is_focused = focused_workspace == workspace_index

			sbar.animate("tanh", 10, function()
				workspace:set({
					icon = { highlight = is_focused },
					label = { highlight = is_focused },
					blur_radius = 30,
					background = {
						color = is_focused and role.highlight_color or role.color,
						border_color = is_focused and role.highlight_color or role.color,
						border_width = is_focused and 0 or 1,
					},
				})
			end)
		end)
	end

	-- Initial setup
	updateWindows()
	updateWorkspaceMonitor()

	-- Subscribe to window creation/destruction events
	root:subscribe("aerospace_workspace_change", function()
		updateWindows()
	end)

	-- Subscribe to front app changes too
	root:subscribe("front_app_switched", function()
		updateWindows()
	end)

	root:subscribe("display_change", function()
		updateWorkspaceMonitor()
		updateWindows()
	end)

	sbar.exec("aerospace list-workspaces --focused", function(focused_workspace)
		focused_workspace = focused_workspace:match("^%s*(.-)%s*$")
		local role = appearance.roles[workspace_role[focused_workspace]]
		workspaces[focused_workspace]:set({
			icon = { highlight = true },
			label = { highlight = true },
			background = {
				color = role.highlight_color,
				border_color = role.highlight_color,
				border_width = 0,
			},
		})
	end)
end)

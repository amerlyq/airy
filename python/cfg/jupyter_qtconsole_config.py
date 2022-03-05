# Configuration file for jupyter-qtconsole.
c = c  # pylint:disable=undefined-variable,self-assigning-variable

# ------------------------------------------------------------------------------
# ConnectionFileMixin(LoggingConfigurable) configuration
# ------------------------------------------------------------------------------
## Mixin for configurable classes that work with connection files

## JSON file in which to store connection info [default: kernel-<pid>.json]
#
#      This file will contain the IP, ports, and authentication key needed to connect
#      clients to this kernel. By default, this file will be created in the security dir
#      of the current profile, but can be specified by absolute path.
#  Default: ''
# c.ConnectionFileMixin.connection_file = ''

## set the control (ROUTER) port [default: random]
#  Default: 0
# c.ConnectionFileMixin.control_port = 0

## set the heartbeat port [default: random]
#  Default: 0
# c.ConnectionFileMixin.hb_port = 0

## set the iopub (PUB) port [default: random]
#  Default: 0
# c.ConnectionFileMixin.iopub_port = 0

## Set the kernel's IP address [default localhost].
#          If the IP address is something other than localhost, then
#          Consoles on other machines will be able to connect
#          to the Kernel, so be careful!
#  Default: ''
# c.ConnectionFileMixin.ip = ''

## set the shell (ROUTER) port [default: random]
#  Default: 0
# c.ConnectionFileMixin.shell_port = 0

## set the stdin (ROUTER) port [default: random]
#  Default: 0
# c.ConnectionFileMixin.stdin_port = 0

#  Choices: any of ['tcp', 'ipc'] (case-insensitive)
#  Default: 'tcp'
# c.ConnectionFileMixin.transport = 'tcp'

# ------------------------------------------------------------------------------
# JupyterConsoleApp(ConnectionFileMixin) configuration
# ------------------------------------------------------------------------------
## Set to display confirmation dialog on exit. You can always use 'exit' or
#  'quit', to force a direct exit without any confirmation.
#  Default: True
# c.JupyterConsoleApp.confirm_exit = True

## JSON file in which to store connection info [default: kernel-<pid>.json]
#  See also: ConnectionFileMixin.connection_file
# c.JupyterConsoleApp.connection_file = ''

## set the control (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.control_port
# c.JupyterConsoleApp.control_port = 0

## Connect to an already running kernel
#  Default: ''
# c.JupyterConsoleApp.existing = ''

## set the heartbeat port [default: random]
#  See also: ConnectionFileMixin.hb_port
# c.JupyterConsoleApp.hb_port = 0

## set the iopub (PUB) port [default: random]
#  See also: ConnectionFileMixin.iopub_port
# c.JupyterConsoleApp.iopub_port = 0

## Set the kernel's IP address [default localhost].
#  See also: ConnectionFileMixin.ip
# c.JupyterConsoleApp.ip = ''

## The kernel manager class to use.
#  Default: 'jupyter_client.manager.KernelManager'
# c.JupyterConsoleApp.kernel_manager_class = 'jupyter_client.manager.KernelManager'

## The name of the default kernel to start.
#  Default: 'python'
# c.JupyterConsoleApp.kernel_name = 'python'

## set the shell (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.shell_port
# c.JupyterConsoleApp.shell_port = 0

## Path to the ssh key to use for logging in to the ssh server.
#  Default: ''
# c.JupyterConsoleApp.sshkey = ''

## The SSH server to use to connect to the kernel.
#  Default: ''
# c.JupyterConsoleApp.sshserver = ''

## set the stdin (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.stdin_port
# c.JupyterConsoleApp.stdin_port = 0

#  See also: ConnectionFileMixin.transport
# c.JupyterConsoleApp.transport = 'tcp'

# ------------------------------------------------------------------------------
# Application(SingletonConfigurable) configuration
# ------------------------------------------------------------------------------
## This is an application.

## The date format used by logging formatters for %(asctime)s
#  Default: '%Y-%m-%d %H:%M:%S'
# c.Application.log_datefmt = '%Y-%m-%d %H:%M:%S'

## The Logging format template
#  Default: '[%(name)s]%(highlevel)s %(message)s'
# c.Application.log_format = '[%(name)s]%(highlevel)s %(message)s'

## Set the log level by value or name.
#  Choices: any of [0, 10, 20, 30, 40, 50, 'DEBUG', 'INFO', 'WARN', 'ERROR', 'CRITICAL']
#  Default: 30
# c.Application.log_level = 30

## Instead of starting the Application, dump configuration to stdout
#  Default: False
# c.Application.show_config = False

## Instead of starting the Application, dump configuration to stdout (as JSON)
#  Default: False
# c.Application.show_config_json = False

# ------------------------------------------------------------------------------
# JupyterApp(Application) configuration
# ------------------------------------------------------------------------------
## Base class for Jupyter applications

## Answer yes to any prompts.
#  Default: False
# c.JupyterApp.answer_yes = False

## Full path of a config file.
#  Default: ''
# c.JupyterApp.config_file = ''

## Specify a config file to load.
#  Default: ''
# c.JupyterApp.config_file_name = ''

## Generate default config file.
#  Default: False
# c.JupyterApp.generate_config = False

## The date format used by logging formatters for %(asctime)s
#  See also: Application.log_datefmt
# c.JupyterApp.log_datefmt = '%Y-%m-%d %H:%M:%S'

## The Logging format template
#  See also: Application.log_format
# c.JupyterApp.log_format = '[%(name)s]%(highlevel)s %(message)s'

## Set the log level by value or name.
#  See also: Application.log_level
# c.JupyterApp.log_level = 30

## Instead of starting the Application, dump configuration to stdout
#  See also: Application.show_config
# c.JupyterApp.show_config = False

## Instead of starting the Application, dump configuration to stdout (as JSON)
#  See also: Application.show_config_json
# c.JupyterApp.show_config_json = False

# ------------------------------------------------------------------------------
# JupyterQtConsoleApp(JupyterApp, JupyterConsoleApp) configuration
# ------------------------------------------------------------------------------
## Answer yes to any prompts.
#  See also: JupyterApp.answer_yes
# c.JupyterQtConsoleApp.answer_yes = False

## Full path of a config file.
#  See also: JupyterApp.config_file
# c.JupyterQtConsoleApp.config_file = ''

## Specify a config file to load.
#  See also: JupyterApp.config_file_name
# c.JupyterQtConsoleApp.config_file_name = ''

##
#  See also: JupyterConsoleApp.confirm_exit
# c.JupyterQtConsoleApp.confirm_exit = True

## JSON file in which to store connection info [default: kernel-<pid>.json]
#  See also: ConnectionFileMixin.connection_file
# c.JupyterQtConsoleApp.connection_file = ''

## set the control (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.control_port
# c.JupyterQtConsoleApp.control_port = 0

## Whether to display a banner upon starting the QtConsole.
#  Default: True
# c.JupyterQtConsoleApp.display_banner = True

## Connect to an already running kernel
#  See also: JupyterConsoleApp.existing
# c.JupyterQtConsoleApp.existing = ''

## Generate default config file.
#  See also: JupyterApp.generate_config
# c.JupyterQtConsoleApp.generate_config = False

## set the heartbeat port [default: random]
#  See also: ConnectionFileMixin.hb_port
# c.JupyterQtConsoleApp.hb_port = 0

## Start the console window with the menu bar hidden.
#  Default: False
# c.JupyterQtConsoleApp.hide_menubar = False

## set the iopub (PUB) port [default: random]
#  See also: ConnectionFileMixin.iopub_port
# c.JupyterQtConsoleApp.iopub_port = 0

## Set the kernel's IP address [default localhost].
#  See also: ConnectionFileMixin.ip
# c.JupyterQtConsoleApp.ip = ''

## The name of the default kernel to start.
#  See also: JupyterConsoleApp.kernel_name
# c.JupyterQtConsoleApp.kernel_name = 'python'

## The date format used by logging formatters for %(asctime)s
#  See also: Application.log_datefmt
# c.JupyterQtConsoleApp.log_datefmt = '%Y-%m-%d %H:%M:%S'

## The Logging format template
#  See also: Application.log_format
# c.JupyterQtConsoleApp.log_format = '[%(name)s]%(highlevel)s %(message)s'

## Set the log level by value or name.
#  See also: Application.log_level
# c.JupyterQtConsoleApp.log_level = 30

## Start the console window maximized.
#  Default: False
# c.JupyterQtConsoleApp.maximize = False

## Use a plaintext widget instead of rich text (plain can't print/save).
#  Default: False
# c.JupyterQtConsoleApp.plain = False

## set the shell (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.shell_port
# c.JupyterQtConsoleApp.shell_port = 0

## Instead of starting the Application, dump configuration to stdout
#  See also: Application.show_config
# c.JupyterQtConsoleApp.show_config = False

## Instead of starting the Application, dump configuration to stdout (as JSON)
#  See also: Application.show_config_json
# c.JupyterQtConsoleApp.show_config_json = False

## Path to the ssh key to use for logging in to the ssh server.
#  See also: JupyterConsoleApp.sshkey
# c.JupyterQtConsoleApp.sshkey = ''

## The SSH server to use to connect to the kernel.
#  See also: JupyterConsoleApp.sshserver
# c.JupyterQtConsoleApp.sshserver = ''

## set the stdin (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.stdin_port
# c.JupyterQtConsoleApp.stdin_port = 0

## path to a custom CSS stylesheet
#  Default: ''
# c.JupyterQtConsoleApp.stylesheet = ''

#  See also: ConnectionFileMixin.transport
# c.JupyterQtConsoleApp.transport = 'tcp'

# ------------------------------------------------------------------------------
# ConsoleWidget(NewBase) configuration
# ------------------------------------------------------------------------------
## An abstract base class for console-type widgets. This class has
#         functionality for:
#
#             * Maintaining a prompt and editing region
#             * Providing the traditional Unix-style console keyboard shortcuts
#             * Performing tab completion
#             * Paging text
#             * Handling ANSI escape codes
#
#         ConsoleWidget also provides a number of utility methods that will be
#         convenient to implementors of a console-style widget.

## Whether to process ANSI escape codes.
#  Default: True
# c.ConsoleWidget.ansi_codes = True

## The maximum number of lines of text before truncation. Specifying a non-
#  positive number disables text truncation (not recommended).
#  Default: 500
# c.ConsoleWidget.buffer_size = 500

## The height of the console at start time in number
#          of characters (will double with `vsplit` paging)
#  Default: 25
# c.ConsoleWidget.console_height = 25

## The width of the console at start time in number
#          of characters (will double with `hsplit` paging)
#  Default: 81
# c.ConsoleWidget.console_width = 81

## Whether to automatically execute on syntactically complete input.
#
#          If False, Shift-Enter is required to submit each execution.
#          Disabling this is mainly useful for non-Python kernels,
#          where the completion check would be wrong.
#  Default: True
# c.ConsoleWidget.execute_on_complete_input = True

## The font family to use for the console.
#          On OSX this defaults to Monaco, on Windows the default is
#          Consolas with fallback of Courier, and on other platforms
#          the default is Monospace.
#  Default: ''
# c.ConsoleWidget.font_family = ''

## The font size. If unconfigured, Qt will be entrusted
#          with the size of the font.
#  Default: 0
# c.ConsoleWidget.font_size = 0

## The type of completer to use. Valid values are:
#
#  'plain'   : Show the available completion as a text list
#              Below the editing area.
#  'droplist': Show the completion in a drop down list navigable
#              by the arrow keys, and from which you can select
#              completion by pressing Return.
#  'ncurses' : Show the completion as a text list which is navigable by
#              `tab` and arrow keys.
#  Choices: any of ['plain', 'droplist', 'ncurses']
#  Default: 'ncurses'
# c.ConsoleWidget.gui_completion = 'ncurses'

## Whether to include output from clients
#          other than this one sharing the same kernel.
#
#          Outputs are not displayed until enter is pressed.
#  Default: False
# c.ConsoleWidget.include_other_output = False
c.ConsoleWidget.include_other_output = True

## The type of underlying text widget to use. Valid values are 'plain', which
#  specifies a QPlainTextEdit, and 'rich', which specifies a QTextEdit.
#  Choices: any of ['plain', 'rich']
#  Default: 'plain'
# c.ConsoleWidget.kind = 'plain'

## Prefix to add to outputs coming from clients other than this one.
#
#          Only relevant if include_other_output is True.
#  Default: '[remote] '
# c.ConsoleWidget.other_output_prefix = '[remote] '

## The type of paging to use. Valid values are:
#
#  'inside'
#     The widget pages like a traditional terminal.
#  'hsplit'
#     When paging is requested, the widget is split horizontally. The top
#     pane contains the console, and the bottom pane contains the paged text.
#  'vsplit'
#     Similar to 'hsplit', except that a vertical splitter is used.
#  'custom'
#     No action is taken by the widget beyond emitting a
#     'custom_page_requested(str)' signal.
#  'none'
#     The text is written directly to the console.
#  Choices: any of ['inside', 'hsplit', 'vsplit', 'custom', 'none']
#  Default: 'inside'
# c.ConsoleWidget.paging = 'inside'

## The visibility of the scrollar. If False then the scrollbar will be
#          invisible.
#  Default: True
# c.ConsoleWidget.scrollbar_visibility = True

# ------------------------------------------------------------------------------
# HistoryConsoleWidget(ConsoleWidget) configuration
# ------------------------------------------------------------------------------
## A ConsoleWidget that keeps a history of the commands that have been
#         executed and provides a readline-esque interface to this history.

## Whether to process ANSI escape codes.
#  See also: ConsoleWidget.ansi_codes
# c.HistoryConsoleWidget.ansi_codes = True

##
#  See also: ConsoleWidget.buffer_size
# c.HistoryConsoleWidget.buffer_size = 500

## The height of the console at start time in number
#  See also: ConsoleWidget.console_height
# c.HistoryConsoleWidget.console_height = 25

## The width of the console at start time in number
#  See also: ConsoleWidget.console_width
# c.HistoryConsoleWidget.console_width = 81

## Whether to automatically execute on syntactically complete input.
#  See also: ConsoleWidget.execute_on_complete_input
# c.HistoryConsoleWidget.execute_on_complete_input = True

## The font family to use for the console.
#  See also: ConsoleWidget.font_family
# c.HistoryConsoleWidget.font_family = ''

## The font size. If unconfigured, Qt will be entrusted
#  See also: ConsoleWidget.font_size
# c.HistoryConsoleWidget.font_size = 0

##
#  See also: ConsoleWidget.gui_completion
# c.HistoryConsoleWidget.gui_completion = 'ncurses'

#  Default: False
# c.HistoryConsoleWidget.history_lock = False

## Whether to include output from clients
#  See also: ConsoleWidget.include_other_output
# c.HistoryConsoleWidget.include_other_output = False

##
#  See also: ConsoleWidget.kind
# c.HistoryConsoleWidget.kind = 'plain'

## Prefix to add to outputs coming from clients other than this one.
#  See also: ConsoleWidget.other_output_prefix
# c.HistoryConsoleWidget.other_output_prefix = '[remote] '

##
#  See also: ConsoleWidget.paging
# c.HistoryConsoleWidget.paging = 'inside'

## The visibility of the scrollar. If False then the scrollbar will be
#  See also: ConsoleWidget.scrollbar_visibility
# c.HistoryConsoleWidget.scrollbar_visibility = True

# ------------------------------------------------------------------------------
# FrontendWidget(HistoryConsoleWidget) configuration
# ------------------------------------------------------------------------------
## A Qt frontend for a generic Python kernel.

## Whether to process ANSI escape codes.
#  See also: ConsoleWidget.ansi_codes
# c.FrontendWidget.ansi_codes = True

#  Default: ''
# c.FrontendWidget.banner = ''

##
#  See also: ConsoleWidget.buffer_size
# c.FrontendWidget.buffer_size = 500

## Whether to clear the console when the kernel is restarted
#  Default: True
# c.FrontendWidget.clear_on_kernel_restart = True

## Whether to ask for user confirmation when restarting kernel
#  Default: True
# c.FrontendWidget.confirm_restart = True

## The height of the console at start time in number
#  See also: ConsoleWidget.console_height
# c.FrontendWidget.console_height = 25

## The width of the console at start time in number
#  See also: ConsoleWidget.console_width
# c.FrontendWidget.console_width = 81

## Whether to draw information calltips on open-parentheses.
#  Default: True
# c.FrontendWidget.enable_calltips = True

## Whether to automatically execute on syntactically complete input.
#  See also: ConsoleWidget.execute_on_complete_input
# c.FrontendWidget.execute_on_complete_input = True

## The font family to use for the console.
#  See also: ConsoleWidget.font_family
# c.FrontendWidget.font_family = ''

## The font size. If unconfigured, Qt will be entrusted
#  See also: ConsoleWidget.font_size
# c.FrontendWidget.font_size = 0

##
#  See also: ConsoleWidget.gui_completion
# c.FrontendWidget.gui_completion = 'ncurses'

#  See also: HistoryConsoleWidget.history_lock
# c.FrontendWidget.history_lock = False

## Whether to include output from clients
#  See also: ConsoleWidget.include_other_output
# c.FrontendWidget.include_other_output = False

##
#  See also: ConsoleWidget.kind
# c.FrontendWidget.kind = 'plain'

## The pygments lexer class to use.
#  Default: traitlets.Undefined
# c.FrontendWidget.lexer_class = traitlets.Undefined

## Prefix to add to outputs coming from clients other than this one.
#  See also: ConsoleWidget.other_output_prefix
# c.FrontendWidget.other_output_prefix = '[remote] '

##
#  See also: ConsoleWidget.paging
# c.FrontendWidget.paging = 'inside'

## The visibility of the scrollar. If False then the scrollbar will be
#  See also: ConsoleWidget.scrollbar_visibility
# c.FrontendWidget.scrollbar_visibility = True

# ------------------------------------------------------------------------------
# IPythonWidget(FrontendWidget) configuration
# ------------------------------------------------------------------------------
## Dummy class for config inheritance. Destroyed below.

## Whether to process ANSI escape codes.
#  See also: ConsoleWidget.ansi_codes
# c.IPythonWidget.ansi_codes = True

#  See also: FrontendWidget.banner
# c.IPythonWidget.banner = ''

##
#  See also: ConsoleWidget.buffer_size
# c.IPythonWidget.buffer_size = 500

## Whether to clear the console when the kernel is restarted
#  See also: FrontendWidget.clear_on_kernel_restart
# c.IPythonWidget.clear_on_kernel_restart = True

## Whether to ask for user confirmation when restarting kernel
#  See also: FrontendWidget.confirm_restart
# c.IPythonWidget.confirm_restart = True

## The height of the console at start time in number
#  See also: ConsoleWidget.console_height
# c.IPythonWidget.console_height = 25

## The width of the console at start time in number
#  See also: ConsoleWidget.console_width
# c.IPythonWidget.console_width = 81

## Whether to draw information calltips on open-parentheses.
#  See also: FrontendWidget.enable_calltips
# c.IPythonWidget.enable_calltips = True

## Whether to automatically execute on syntactically complete input.
#  See also: ConsoleWidget.execute_on_complete_input
# c.IPythonWidget.execute_on_complete_input = True

## The font family to use for the console.
#  See also: ConsoleWidget.font_family
# c.IPythonWidget.font_family = ''

## The font size. If unconfigured, Qt will be entrusted
#  See also: ConsoleWidget.font_size
# c.IPythonWidget.font_size = 0

##
#  See also: ConsoleWidget.gui_completion
# c.IPythonWidget.gui_completion = 'ncurses'

#  See also: HistoryConsoleWidget.history_lock
# c.IPythonWidget.history_lock = False

## Whether to include output from clients
#  See also: ConsoleWidget.include_other_output
# c.IPythonWidget.include_other_output = False

##
#  See also: ConsoleWidget.kind
# c.IPythonWidget.kind = 'plain'

## The pygments lexer class to use.
#  See also: FrontendWidget.lexer_class
# c.IPythonWidget.lexer_class = traitlets.Undefined

## Prefix to add to outputs coming from clients other than this one.
#  See also: ConsoleWidget.other_output_prefix
# c.IPythonWidget.other_output_prefix = '[remote] '

##
#  See also: ConsoleWidget.paging
# c.IPythonWidget.paging = 'inside'

## The visibility of the scrollar. If False then the scrollbar will be
#  See also: ConsoleWidget.scrollbar_visibility
# c.IPythonWidget.scrollbar_visibility = True

# ------------------------------------------------------------------------------
# JupyterWidget(IPythonWidget) configuration
# ------------------------------------------------------------------------------
## A FrontendWidget for a Jupyter kernel.

## Whether to process ANSI escape codes.
#  See also: ConsoleWidget.ansi_codes
# c.JupyterWidget.ansi_codes = True

#  See also: FrontendWidget.banner
# c.JupyterWidget.banner = ''

##
#  See also: ConsoleWidget.buffer_size
# c.JupyterWidget.buffer_size = 500

## Whether to clear the console when the kernel is restarted
#  See also: FrontendWidget.clear_on_kernel_restart
# c.JupyterWidget.clear_on_kernel_restart = True

## Whether to ask for user confirmation when restarting kernel
#  See also: FrontendWidget.confirm_restart
# c.JupyterWidget.confirm_restart = True

## The height of the console at start time in number
#  See also: ConsoleWidget.console_height
# c.JupyterWidget.console_height = 25

## The width of the console at start time in number
#  See also: ConsoleWidget.console_width
# c.JupyterWidget.console_width = 81

## A command for invoking a GUI text editor. If the string contains a {filename}
#  format specifier, it will be used. Otherwise, the filename will be appended to
#  the end the command. To use a terminal text editor, the command should launch
#  a new terminal, e.g. ``"gnome-terminal -- vim"``.
#  Default: ''
# c.JupyterWidget.editor = ''

## The editor command to use when a specific line number is requested. The string
#  should contain two format specifiers: {line} and {filename}. If this parameter
#  is not specified, the line number option to the %edit magic will be ignored.
#  Default: ''
# c.JupyterWidget.editor_line = ''

## Whether to draw information calltips on open-parentheses.
#  See also: FrontendWidget.enable_calltips
# c.JupyterWidget.enable_calltips = True

## Whether to automatically execute on syntactically complete input.
#  See also: ConsoleWidget.execute_on_complete_input
# c.JupyterWidget.execute_on_complete_input = True

## The font family to use for the console.
#  See also: ConsoleWidget.font_family
# c.JupyterWidget.font_family = ''

## The font size. If unconfigured, Qt will be entrusted
#  See also: ConsoleWidget.font_size
# c.JupyterWidget.font_size = 0

##
#  See also: ConsoleWidget.gui_completion
# c.JupyterWidget.gui_completion = 'ncurses'

#  See also: HistoryConsoleWidget.history_lock
# c.JupyterWidget.history_lock = False

#  Default: 'In [<span class="in-prompt-number">%i</span>]: '
# c.JupyterWidget.in_prompt = 'In [<span class="in-prompt-number">%i</span>]: '

## Whether to include output from clients
#  See also: ConsoleWidget.include_other_output
# c.JupyterWidget.include_other_output = False

#  Default: '\n'
# c.JupyterWidget.input_sep = '\n'

##
#  See also: ConsoleWidget.kind
# c.JupyterWidget.kind = 'plain'

## The pygments lexer class to use.
#  See also: FrontendWidget.lexer_class
# c.JupyterWidget.lexer_class = traitlets.Undefined

## Prefix to add to outputs coming from clients other than this one.
#  See also: ConsoleWidget.other_output_prefix
# c.JupyterWidget.other_output_prefix = '[remote] '

#  Default: 'Out[<span class="out-prompt-number">%i</span>]: '
# c.JupyterWidget.out_prompt = 'Out[<span class="out-prompt-number">%i</span>]: '

#  Default: ''
# c.JupyterWidget.output_sep = ''

#  Default: ''
# c.JupyterWidget.output_sep2 = ''

##
#  See also: ConsoleWidget.paging
# c.JupyterWidget.paging = 'inside'

## The visibility of the scrollar. If False then the scrollbar will be
#  See also: ConsoleWidget.scrollbar_visibility
# c.JupyterWidget.scrollbar_visibility = True

## A CSS stylesheet. The stylesheet can contain classes for:
#      1. Qt: QPlainTextEdit, QFrame, QWidget, etc
#      2. Pygments: .c, .k, .o, etc. (see PygmentsHighlighter)
#      3. QtConsole: .error, .in-prompt, .out-prompt, etc
#  Default: ''
# c.JupyterWidget.style_sheet = ''

## If not empty, use this Pygments style for syntax highlighting. Otherwise, the
#  style sheet is queried for Pygments style information.
#  Default: ''
# c.JupyterWidget.syntax_style = ''
c.JupyterWidget.syntax_style = "solarized-dark"

# ------------------------------------------------------------------------------
# KernelManager(ConnectionFileMixin) configuration
# ------------------------------------------------------------------------------
## Manages a single kernel in a subprocess on this host.
#
#      This version starts kernels with Popen.

## Should we autorestart the kernel if it dies.
#  Default: True
# c.KernelManager.autorestart = True

## JSON file in which to store connection info [default: kernel-<pid>.json]
#  See also: ConnectionFileMixin.connection_file
# c.KernelManager.connection_file = ''

## set the control (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.control_port
# c.KernelManager.control_port = 0

## set the heartbeat port [default: random]
#  See also: ConnectionFileMixin.hb_port
# c.KernelManager.hb_port = 0

## set the iopub (PUB) port [default: random]
#  See also: ConnectionFileMixin.iopub_port
# c.KernelManager.iopub_port = 0

## Set the kernel's IP address [default localhost].
#  See also: ConnectionFileMixin.ip
# c.KernelManager.ip = ''

## set the shell (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.shell_port
# c.KernelManager.shell_port = 0

## Time to wait for a kernel to terminate before killing it, in seconds. When a
#  shutdown request is initiated, the kernel will be immediately sent an
#  interrupt (SIGINT), followedby a shutdown_request message, after 1/2 of
#  `shutdown_wait_time`it will be sent a terminate (SIGTERM) request, and finally
#  at the end of `shutdown_wait_time` will be killed (SIGKILL). terminate and
#  kill may be equivalent on windows.  Note that this value can beoverridden by
#  the in-use kernel provisioner since shutdown times mayvary by provisioned
#  environment.
#  Default: 5.0
# c.KernelManager.shutdown_wait_time = 5.0

## set the stdin (ROUTER) port [default: random]
#  See also: ConnectionFileMixin.stdin_port
# c.KernelManager.stdin_port = 0

#  See also: ConnectionFileMixin.transport
# c.KernelManager.transport = 'tcp'

# ------------------------------------------------------------------------------
# KernelRestarter(LoggingConfigurable) configuration
# ------------------------------------------------------------------------------
## Monitor and autorestart a kernel.

## Whether to include every poll event in debugging output.
#
#          Has to be set explicitly, because there will be *a lot* of output.
#  Default: False
# c.KernelRestarter.debug = False

## Whether to choose new random ports when restarting before the kernel is alive.
#  Default: True
# c.KernelRestarter.random_ports_until_alive = True

## The number of consecutive autorestarts before the kernel is presumed dead.
#  Default: 5
# c.KernelRestarter.restart_limit = 5

## The time in seconds to consider the kernel to have completed a stable start
#  up.
#  Default: 10.0
# c.KernelRestarter.stable_start_time = 10.0

## Kernel heartbeat interval in seconds.
#  Default: 3.0
# c.KernelRestarter.time_to_dead = 3.0

# ------------------------------------------------------------------------------
# Session(Configurable) configuration
# ------------------------------------------------------------------------------
## Object for handling serialization and sending of messages.
#
#      The Session object handles building messages and sending them
#      with ZMQ sockets or ZMQStream objects.  Objects can communicate with each
#      other over the network via Session objects, and only need to work with the
#      dict-based IPython message spec. The Session will handle
#      serialization/deserialization, security, and metadata.
#
#      Sessions support configurable serialization via packer/unpacker traits,
#      and signing with HMAC digests via the key/keyfile traits.
#
#      Parameters
#      ----------
#
#      debug : bool
#          whether to trigger extra debugging statements
#      packer/unpacker : str : 'json', 'pickle' or import_string
#          importstrings for methods to serialize message parts.  If just
#          'json' or 'pickle', predefined JSON and pickle packers will be used.
#          Otherwise, the entire importstring must be used.
#
#          The functions must accept at least valid JSON input, and output
#  *bytes*.
#
#          For example, to use msgpack:
#          packer = 'msgpack.packb', unpacker='msgpack.unpackb'
#      pack/unpack : callables
#          You can also set the pack/unpack callables for serialization directly.
#      session : bytes
#          the ID of this Session object.  The default is to generate a new UUID.
#      username : unicode
#          username added to message headers.  The default is to ask the OS.
#      key : bytes
#          The key used to initialize an HMAC signature.  If unset, messages
#          will not be signed or checked.
#      keyfile : filepath
#          The file containing a key.  If this is set, `key` will be initialized
#          to the contents of the file.

## Threshold (in bytes) beyond which an object's buffer should be extracted to
#  avoid pickling.
#  Default: 1024
# c.Session.buffer_threshold = 1024

## Whether to check PID to protect against calls after fork.
#
#          This check can be disabled if fork-safety is handled elsewhere.
#  Default: True
# c.Session.check_pid = True

## Threshold (in bytes) beyond which a buffer should be sent without copying.
#  Default: 65536
# c.Session.copy_threshold = 65536

## Debug output in the Session
#  Default: False
# c.Session.debug = False

## The maximum number of digests to remember.
#
#          The digest history will be culled when it exceeds this value.
#  Default: 65536
# c.Session.digest_history_size = 65536

## The maximum number of items for a container to be introspected for custom serialization.
#          Containers larger than this are pickled outright.
#  Default: 64
# c.Session.item_threshold = 64

## execution key, for signing messages.
#  Default: b''
# c.Session.key = b''

## path to file containing execution key.
#  Default: ''
# c.Session.keyfile = ''

## Metadata dictionary, which serves as the default top-level metadata dict for
#  each message.
#  Default: {}
# c.Session.metadata = {}

## The name of the packer for serializing messages.
#              Should be one of 'json', 'pickle', or an import name
#              for a custom callable serializer.
#  Default: 'json'
# c.Session.packer = 'json'

## The UUID identifying this session.
#  Default: ''
# c.Session.session = ''

## The digest scheme used to construct the message signatures.
#          Must have the form 'hmac-HASH'.
#  Default: 'hmac-sha256'
# c.Session.signature_scheme = 'hmac-sha256'

## The name of the unpacker for unserializing messages.
#          Only used with custom functions for `packer`.
#  Default: 'json'
# c.Session.unpacker = 'json'

## Username for the Session. Default is your system username.
#  Default: 'amer'
# c.Session.username = 'amer'

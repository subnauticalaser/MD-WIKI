local lib = {}; do
	lib.__index = lib

	lib.threadlevel = {} do
		lib.threadlevel.ExecutionFailure = {}
		lib.threadlevel.ExecutionTimeout = {}
		lib.threadlevel.ExecutionYeild = {}
		lib.threadlevel.ExecutionRunAgian = {}
		lib.threadlevel.ExecutionIdentity = {}
		lib.threadlevel.SignalExecutionError = {}
	end

	lib.debuglevel = {} do
		lib.debuglevel.ExecutionSuccess = {}
		lib.debuglevel.ExecutionSuccess_NoInformation = {}
		lib.debuglevel.ExecutionWarning = {}
	end


	lib.threadrunexecutor = function(func)
		local suc, res = pcall(func)

		if not res or type(res) ~= 'string' then
			res = 'Execution Successfull'
		end


		if suc then
			lib.debugexecution(lib.debuglevel.ExecutionSuccess, '[Executor Debug]: ' .. res, 2)
		else
			lib.threadexecution(lib.threadlevel.ExecutionFailure, '[Executor Error]: ' .. res, 2)
		end
	end


	lib.debugexecution = function(op, message, level)
		local bitWall = '---------'

		if op == lib.debuglevel.ExecutionSuccess then
			print(('\n%s Execution Debug by SL-Runtime %s\n%s\n%s Execution Debug Stack %s\n%s'):format(bitWall, bitWall, message, bitWall, bitWall, debug.traceback(nil, (level or 1) + 1)))
		elseif op == lib.debuglevel.ExecutionWarning then
			warn(('\n%s Execution Debug by SL-Runtime %s\n%s\n%s Execution Debug Stack %s\n%s'):format(bitWall, bitWall, message, bitWall, bitWall, debug.traceback(nil, 2)))
		end
	end

	lib.threadexecution = function(op, message, level, ...)
		if op == lib.threadlevel.ExecutionFailure then
			local stack = debug.traceback(nil, (level or 1) + 1)
			local function frameworkExecutionError()
				error(('\n--------- Thread Execution Failure by SL-Runtime ---------\n%s\n--------- Thread SL-Runtime Stack ---------\n%s'):format(message, stack), 2)
			end

			task.spawn(frameworkExecutionError)
			coroutine.yield()
		elseif op == lib.threadlevel.ExecutionYeild then
			warn(('\n--------- Thread Execution Yeilded by SL-Runtime ---------\n%s'):format(debug.traceback(nil, 2)))
			coroutine.yield()
		elseif op == lib.threadlevel.ExecutionTimeout then
			local timeoutTime = {...};
			warn(('\n--------- Thread Execution Timeout by SL-Runtime ---------\n%s'):format(debug.traceback(nil, 2)))

			local timeIntilResume = timeoutTime[1] + tick();

			repeat
				task.wait()
			until tick() >= timeIntilResume
		elseif op == lib.threadlevel.ExecutionRunAgian then
			local func = table.pack(...)[1]
		elseif op == lib.threadlevel.ExecutionIdentity then
			local stack = debug.traceback(nil, (level or 1) + 1)
			local co = coroutine.running()
		elseif op == lib.threadlevel.SignalExecutionError then
			local stack = debug.traceback(nil, (level or 1) + 1)
			local function frameworkSignalError()
				error(('\n--------- Signal Error sent by SL-Runtime ---------\n%s\n--------- Signal SL-Runtime Stack ---------\n%s'):format(message, stack), 1)
			end

			task.spawn(frameworkSignalError)
			coroutine.yield()
		end
	end
end



local GoodSignal = (function()
	--------------------------------------------------------------------------------
	--               Batched Yield-Safe Signal Implementation                     --
	-- This is a Signal class which has effectively identical behavior to a       --
	-- normal RBXScriptSignal, with the only difference being a couple extra      --
	-- stack frames at the bottom of the stack trace when an error is thrown.     --
	-- This implementation caches runner coroutines, so the ability to yield in   --
	-- the signal handlers comes at minimal extra cost over a naive signal        --
	-- implementation that either always or never spawns a thread.                --
	--                                                                            --
	-- API:                                                                       --
	--   local Signal = require(THIS MODULE)                                      --
	--   local sig = Signal.new()                                                 --
	--   local connection = sig:Connect(function(arg1, arg2, ...) ... end)        --
	--   local parallelConnection = sig:ConnectParallel(function(...) ... end)    --
	--   sig:Fire(arg1, arg2, ...)                                                --
	--   connection:Disconnect()                                                  --
	--   sig:DisconnectAll()                                                      --
	--   local arg1, arg2, ... = sig:Wait()                                       --
	--                                                                            --
	-- Licence:                                                                   --
	--   Licenced under the MIT licence.                                          --
	--                                                                            --
	-- Authors:                                                                   --
	--   stravant - July 31st, 2021 - Created the file.                           --
	--   Modified by SL - February 12, 2025 - Added ConnectParallel.              --
	--------------------------------------------------------------------------------

	-- The currently idle thread to run the next handler on
	local freeRunnerThread = nil
	local freeParallelRunnerThread = nil

	-- Function which acquires the currently idle handler runner thread, runs the
	-- function fn on it, and then releases the thread, returning it to being the
	-- currently idle one.
	-- If there was a currently idle runner thread already, that's okay, that old
	-- one will just get thrown and eventually GCed.
	local function acquireRunnerThreadAndCallEventHandler(fn, ...)
		local acquiredRunnerThread = freeRunnerThread
		freeRunnerThread = nil
		fn(...)
		-- The handler finished running, this runner thread is free again.
		freeRunnerThread = acquiredRunnerThread
	end

	-- Coroutine runner that we create coroutines of. The coroutine can be
	-- repeatedly resumed with functions to run followed by the argument to run
	-- them with.
	local function runEventHandlerInFreeThread()
		-- Note: We cannot use the initial set of arguments passed to
		-- runEventHandlerInFreeThread for a call to the handler, because those
		-- arguments would stay on the stack for the duration of the thread's
		-- existence, temporarily leaking references. Without access to raw bytecode
		-- there's no way for us to clear the "..." references from the stack.
		while true do
			acquireRunnerThreadAndCallEventHandler(coroutine.yield())
		end
	end

	-- Connection class
	local Connection = {}
	Connection.__index = Connection

	function Connection.new(signal, fn, isParallel)
		return setmetatable({
			_connected = true,
			_signal = signal,
			_fn = fn,
			_next = false,
			_isParallel = isParallel or false,
		}, Connection)
	end

	function Connection:Disconnect()
		self._connected = false

		-- Unhook the node, but DON'T clear it. That way any fire calls that are
		-- currently sitting on this node will be able to iterate forwards off of
		-- it, but any subsequent fire calls will not hit it, and it will be GCed
		-- when no more fire calls are sitting on it.
		if self._signal._handlerListHead == self then
			self._signal._handlerListHead = self._next
		else
			local prev = self._signal._handlerListHead
			while prev and prev._next ~= self do
				prev = prev._next
			end
			if prev then
				prev._next = self._next
			end
		end
	end

	-- Make Connection strict
	setmetatable(Connection, {
		__index = function(_, key)
			error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
		end,
		__newindex = function(_, key)
			error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
		end,
	})

	export type Connection = {
		Disconnect: (self: Connection) -> (),
	}

	export type Signal<T...> = {
		Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
		ConnectParallel: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
		Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
		Fire: (self: Signal<T...>, T...) -> (),
		Wait: (self: Signal<T...>) -> (),
	}

	-- Signal class
	local Signal = {}
	Signal.__index = Signal

	function Signal.new<T...>(): Signal<T...>
		return setmetatable({
			_handlerListHead = false,
		}, Signal) :: any
	end

	function Signal:Connect(fn)
		local connection = Connection.new(self, fn, false)
		if self._handlerListHead then
			connection._next = self._handlerListHead
			self._handlerListHead = connection
		else
			self._handlerListHead = connection
		end
		return connection
	end


	-- Establishes a function to be called when the event fires. Returns an RBXScriptConnection object associated
	-- with the connection. When the event fires, the signal callback is executed in a desynchronized state. Using
	-- ConnectParallel is similar to, but more efficient than, using Connect followed by a call to
	-- task.desynchronize() in the signal handler.
	--
	-- Note: Scripts that connect in parallel must be rooted under an Actor.
	function Signal:ConnectParallel(fn)
		assert(typeof(fn) == "function", "ConnectParallel expects a function!")

		local connection = Connection.new(self, fn, true)

		if self._handlerListHead then
			connection._next = self._handlerListHead
			self._handlerListHead = connection
		else
			self._handlerListHead = connection
		end

		--print("? Successfully connected:", fn) -- Debug print
		return connection
	end


	-- Disconnect all handlers. Since we use a linked list it suffices to clear the
	-- reference to the head handler.
	function Signal:DisconnectAll()
		self._handlerListHead = false
	end


	local function isParentPartOfClassName(className: string)
		local scriptfenv = getfenv(3)

		if not (scriptfenv.script) then
			error('getfenv did not return the level of information sended at it!', 3)
		end

		local newParent = scriptfenv.script;
		local successfull = false;
		for _ = 1, math.huge do
			if newParent == nil then
				return successfull
			end

			if newParent:IsA(className) then
				successfull = true
			end

			newParent = newParent.Parent
		end
	end


	-- Signal:Fire(...) implemented by running the handler functions on the
	-- coRunnerThread, and any time the resulting thread yielded without returning
	-- to us, that means that it yielded to the Roblox scheduler and has been taken
	-- over by Roblox scheduling, meaning we have to make a new coroutine runner.
	function Signal:Fire(...)
		local suc, res
		--print("Firing signal with arguments:", ...) -- Debug print
		local args = {...}

		local item = self._handlerListHead
		while item do
			--print("Checking handler:", item._fn) -- Debug print

			if item._connected then
				if item._isParallel then
					--print("Firing in parallel...") -- Debug print

					-- Ensure a free parallel runner thread exists
					if not freeParallelRunnerThread or coroutine.status(freeParallelRunnerThread) == "dead" then
						--print("Creating new parallel thread...") -- Debug print
						if not isParentPartOfClassName('Actor') then
							error('Scripts that connect in parallel must be rooted under an Actor.', 0)
						end

						freeParallelRunnerThread = coroutine.create(function()
							task.desynchronize()
							--print('Running Corotinue mode!')
							do
								local fn, args = item._fn, args
								if not fn then warn('Function broke Warning!') return end
								--print("Executing parallel function...") -- Debug print
								args = args or {}
								fn(table.unpack(args, 1, #args))
							end
						end)
						coroutine.resume(freeParallelRunnerThread)
					end

					-- Resume parallel execution
					suc,res=coroutine.resume(freeParallelRunnerThread, item._fn, table.pack(...))
				else
					-- print("Firing normally...") -- Debug print
					if not freeRunnerThread or coroutine.status(freeRunnerThread) == "dead" then
						freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
						coroutine.resume(freeRunnerThread)
					end
					suc,res=coroutine.resume(freeRunnerThread, item._fn, table.pack(...))
				end
			end
			item = item._next
		end

		repeat
			task.wait()
		until suc ~= nil


		if not suc then
			lib.threadexecution(lib.threadlevel.SignalExecutionError, res, 2)
		end
	end


	-- Implement Signal:Wait() in terms of a temporary connection using
	-- a Signal:Connect() which disconnects itself.
	function Signal:Wait()
		local waitingCoroutine = coroutine.running()
		local cn
		cn = self:Connect(function(...)
			cn:Disconnect()
			task.spawn(waitingCoroutine, ...)
		end)
		return coroutine.yield()
	end

	-- Implement Signal:Once() in terms of a connection which disconnects
	-- itself before running the handler.
	function Signal:Once(fn)
		local cn
		cn = self:Connect(function(...)
			if cn._connected then
				cn:Disconnect()
			end
			fn(...)
		end)
		return cn
	end



	-- Make signal strict
	setmetatable(Signal, {
		__index = function(_, key)
			error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
		end,
		__newindex = function(_, key)
			error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
		end,
	})

	return Signal
end)()


local framework = {} do

end



local sig = GoodSignal.new()


sig:Connect(function()
	local hello = function()
		local k = function()
			error('Fatal error: Bit32 should be its own Array! Bit32 is Bit64! due to encryption, unknown type! exit code -1')
		end

		k()
	end


	hello()
end)




lib.debugexecution(lib.debuglevel.ExecutionWarning, 'LOL')

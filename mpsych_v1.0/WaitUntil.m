
function [ret, func_ret, waited_time] = WaitUntil (func, func_args, timeout, mode, windowPtr, dontclear)
%
% function [ret, func_ret, waited_time] = WaitUntil (func, func_args, timeout, mode, windowPtr)
%
% calls function func repeatedly until it returns a positive value or a
% specified timeout period is passed. the time unit is second (not
% millisecond).
%
% func is very flexible. for example it can be checking for some keyboard
% input, checking if a digital line input is set, checking for a fixation
% break or saccade, etc. to make it even more powerful you also define any
% combination of various conditions in func and return different values
% depending on the satisifed condition. the returned value is then passed
% to the function that called WaitUntil.
% mode defines the frequency of calling func and checking for timeout. if
% it is set to 0, WaitUntil will synchronize itself with the vertical
% blanking of the screen, i.e. func and timeout will be checked after each
% vertical blank. if mode is positive number
%
%
% Input
%   func    a function that checks for termination conditions. if func
%           returns a nonzero values it means a termination condition is
%           satisfied. the returned value can be a string. func can be
%           empty, in this case timeout must be set
%   func_args   arguments that are passed directly to func. use cell or
%           struct to pass multiple arguments
%   timeout is the conditions in func are not satisfied after timeout the
%           function will terminate automayically. should be defined in
%           seconds. if timeout is empty, WaitUntil waits indefintely for
%           func to return a positive value.
%   mode    0 to synchronize the call to func and check for timeout to the
%           screen vertical blanking.
%           a positive number means checking should be performed every mode
%           seconds.
%           default value for mode is 0.02 seconds (20 ms)
%   windowPtr   if mode is 0 windowPtr defines the window pointer that will
%           be passed to Screen('Flip', ...)
%   dontclear   if set to 1, flip will not clear the framebuffer after Flip
%           - this allows incremental drawing of stimuli. the default is
%           zero, which will clear the framebuffer to background color
%           after each flip. a value of 2 will prevent Flip from doing
%           anything to the framebuffer after flip.
%
% Output
%   ret     1 if func is satisfied
%           2 if timeout is satisfied
%           0 if input arguments are invalid
%   func_ret    the last value returned by func. if func is not specified
%           func_ret will be set to zero automatically
%   waited_time defines how much time (in seconds) was passed before the
%           function returns
%
%
%

%
% 09/26/07  Developed by RK
%


ret = 0;
func_ret = 0;
waited_time = 0;

ref_time = GetSecs;

if nargin == 0 || ...
        (nargin < 3 && isempty(func)) || ...
        (isempty(func) && (isempty(timeout) || timeout<=0))
    return;
end;

if isempty(func),
    func = @dummy_func;
    func_args = [];
end;

if isempty(timeout),
    timeout = inf;
end;

if nargin < 4 || isempty(mode),
    mode = 0.02;
end;

if nargin < 6 || isempty(dontclear)
    dontclear = 0;
end;

% mode should be zero or a positive number. if mode is zero windowPtr
% should refer to an onscreen window. use Screen('WindowKind') to know if
% windowPtr is an onscreen window
if mode < 0 || ...
        (mode==0 && (nargin<5 || isempty(windowPtr) || Screen(windowPtr,'WindowKind')~=1)),
    return;
end;

while 1,
    if isempty(func_args),
        func_ret = func();
    else
        func_ret = func(func_args{:});
    end;
    waited_time = GetSecs - ref_time;
    if ~isequal(func_ret,0),
        ret = 1;
        return;
    end;
    if waited_time >= timeout,
        ret = 2;
        return;
    end;
    if mode == 0,
        Screen('Flip', windowPtr, 0, dontclear);
    else
        WaitSecs(mode);
    end
end;


function ret = dummy_func()
ret = 0;





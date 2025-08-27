--!strict
type void = nil;
type ThreadsAPI = {
	init : (self : ThreadsAPI, threads : number, height : number, same_color_thres : number, raycast_dist : number) -> void;
	render : (self : ThreadsAPI) -> void;
}

local ThreadsAPI = {} :: ThreadsAPI;
local ACTOR_TEMPLETE = script.Actor;
local actors : {Actor} = {};

function ThreadsAPI:init(threads, height,same_color_thres : number, raycast_dist : number)
	
	local per_thread = height // threads
	for i=1,threads do
		local actor = ACTOR_TEMPLETE:Clone();
		actor.Parent = script
		actor.Script.Enabled = true;
		actor.thread_init_complete.Event:Wait()
		actor:SendMessage("init",(per_thread * (i - 1)),(per_thread * i),same_color_thres,raycast_dist);
		table.insert(actors,actor);
	end
	
	return;
end

function ThreadsAPI:render()
	local num_done = 0
	local is_completed = Instance.new("BindableEvent")
	
	
	for _,thread in actors do
		thread:SendMessage("render")
	end
	
	for index,thread in actors do
		local completed_event = thread.render_completed :: BindableEvent
		completed_event.Event:Once(function() 
			num_done +=1
			is_completed:Fire()
		end)
	end
	repeat
		is_completed.Event:Wait()
	until num_done >= #actors
	
	return
end
return ThreadsAPI;

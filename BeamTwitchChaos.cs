using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.NetworkInformation;
using CrowdControl.Common;
using JetBrains.Annotations;
using ConnectorType = CrowdControl.Common.ConnectorType;

namespace CrowdControl.Games.Packs.BeamNG;

[UsedImplicitly]
public class BeamNG : SimpleTCPPack {
    public override string Host => "0.0.0.0";
    public override ushort Port => 43384;

    public override ISimpleTCPPack.MessageFormat MessageFormat => ISimpleTCPPack.MessageFormat.CrowdControl;
    public override ISimpleTCPPack.QuantityFormat QuantityFormat => ISimpleTCPPack.QuantityFormat.ParameterAndField;

    public BeamNG (UserRecord player, Func<CrowdControlBlock, bool> responseHandler, Action<object> statusUpdateHandler) : base(player, responseHandler, statusUpdateHandler) { }

    public override Game Game { get; } = new("BeamNG.Drive", "BeamNG", "PC", ConnectorType.SimpleTCPServerConnector);

    public static ParameterDef GravityParameters { get; } = new ParameterDef("Gravity", "gravity",
        new Parameter("Pluto", "grav_pluto"),
        new Parameter("Moon", "grav_moon"),
        new Parameter("Mars", "grav_mars"),
        new Parameter("Venus", "grav_venus"),
        new Parameter("Saturn", "grav_saturn"),
        new Parameter("Double Earth", "grav_double_earth"),
        new Parameter("Jupiter", "grav_jupiter")
    );

    public static ParameterDef SimspeedParameters { get; } = new ParameterDef("Sim Speed", "simspeed", 
        new Parameter("Real Speed", "time_1"),
        new Parameter("Half Speed", "time_2"),
        new Parameter("1/4 Speed", "time_4"),
        new Parameter("1/8 Speed", "time_8"),
        new Parameter("1/16 Speed", "time_16")   
    );

    public static string UiEffects = "UI Effects";
    public static string VehicleEffects = "Vehicle Effects";
    public static string EnvironmentEffects = "Environment Effects";
    public static string CameraEffects = "Camera Effects";
    public static string FunEffects = "Fun Effects";
    public static string CcEffects = "Crowd Effects";

    public override EffectList Effects { get; } = new Effect[] {
        new("Add a DVD Logo", "dvd") { Price = 15, Description = "Something everyone in chat can watch", Quantity = new QuantityRange(1, 10), DefaultQuantity = 1, Category = UiEffects },
        new("Add an Ad", "ad") { Price = 15, Description = "You've won a new car!", Quantity = new QuantityRange(1, 10), DefaultQuantity = 1, Category = UiEffects },
        new("Narrow the Screen", "view_narrow") { Price = 40, Description = "We can see too much, can you do something about that?", Category = UiEffects },
        new("Squish the Screen", "view_squish") { Price = 40, Description = "We can see too much, can you do something about that?", Category = UiEffects },
        // new("Shake the Screen", "view_shake") { Price = 80, Description = "Add some drama", Category = new EffectGrouping("UI") },
        new("Clear the Screen", "uireset") { Price = 15, Description = "Can we see again?", Category = UiEffects },

        new("Pop a Tire", "pop") { Price = 150, Description = "Make it a bit harder to drive", Category = VehicleEffects },
        new("Start a Fire", "fire") { Price = 400, Description = "Everyone knows Twitch likes a hot stream", Category = VehicleEffects },
        new("Explode", "explode") { Price = 1200, Description = "When the stream is going a little *too* well", Category = VehicleEffects },
        new("Extinguish", "extinguish") { Price = 25, Description = "Give the streamer a second chance", Category = VehicleEffects },
        new("Ghost", "ghost") { Price = 50, Description = "Invite a ghost to the party", Category = VehicleEffects },
        new("Toggle the Ignition", "ignition") { Price = 50, Description = "Jiggle the car keys", Category = VehicleEffects },
        new("Set off the Alarm", "alarm") { Price = 50, Description = "I think someone might be trying to break into our car", Category = VehicleEffects },
        //new("Lowrider", "slam") { Price = 150, Description = "Time to get fancy", Category = VehicleEffects },
        new("Randomize the Paint", "random_paint") { Price = 20, Description = "Let's get some fresh new paint", Category = VehicleEffects },
        //new("Randomize the Tune", "random_tune") { Price = 200, Description = "I know how to tune, trust me", Category = VehicleEffects },
        //new("Randomize the Parts", "random_part") { Price = 1000, Description = "Let's order some cool new parts", Category = VehicleEffects },
        //new("Damage a Part", "random_damage") { Price = 50, Description = "Give something a break", Category = VehicleEffects },
        //new("Repair the Car", "repair") { Price = 50, Description = "Nothing a bit of percussive maintenance can't fix", Category = VehicleEffects },
        new("Turn on the Forcefield", "forcefield") { Price = 75, Description = "Push everything away", Category = VehicleEffects },
        new("Turn on the Negative Forcefield", "attractfield") { Price = 250, Description = "Pull everything in", Category = VehicleEffects },
        new("Turn Around (Fast)", "spin") { Price = 200, Description = "I think we're going the wrong way", Category = VehicleEffects },
        new("Bump the Car Left", "nudge_l") { Price = 50, Description = "Give it a bit of a push", Category = VehicleEffects },
        new("Bump the Car Right", "nudge_r") { Price = 50, Description = "Give it a bit of a push", Category = VehicleEffects },
        new("Kick the Car Left", "kick_l") { Price = 175, Description = "Ok now you might be going too far", Category = VehicleEffects },
        new("Kick the Car Right", "kick_r") { Price = 175, Description = "Ok now you might be going too far", Category = VehicleEffects },
        new("Jump the Car", "jump_l") { Price = 100, Description = "Woah, sick jump!", Category = VehicleEffects },
        new("Jump the Car Really High", "jump_h") { Price = 300, Description = "Hang on, are you a superhero?!", Category = VehicleEffects },
        new("Tilt the Car Left", "tilt_l") { Price = 100, Description = "What's better than cow tipping?", Category = VehicleEffects },
        new("Tilt the Car Right", "tilt_r") { Price = 100, Description = "What's better than cow tipping?", Category = VehicleEffects },
        new("Do a Barrel Roll Left", "roll_l") { Price = 300, Description = "Ackshually it's not a barrel roll", Category = VehicleEffects },
        new("Do a Barrel Roll Right", "roll_r") { Price = 300, Description = "Ackshually it's not a barrel roll", Category = VehicleEffects },
        new("Give a Small Boost", "boost_l") { Price = 50, Description = "Is this one of those video games?", Category = VehicleEffects },
        new("Rocket Boost", "boost_h") { Price = 200, Description = "Time to go Sonic Fast", Category = VehicleEffects },
        new("Do a Kickflip", "kickflip") { Price = 350, Description = "Did you know you look a lot like Tony Hawk?", Category = VehicleEffects },
        //new("Skip the Car", "skip") { Price = 100, Description = "Skipping is a healthy way to move around", Category = VehicleEffects },
        new("Sticky Throttle", "sticky_throttle") { Price = 125, Description = "Onward!", Category = VehicleEffects },
        new("Sticky Handbrake", "sticky_parkingbrake") { Price = 125, Description = "Do a drift!", Category = VehicleEffects },
        new("Sticky Brake", "sticky_brake") { Price = 75, Description = "We're going too fast!", Category = VehicleEffects },
        new("Yank the Wheel Left", "sticky_turn_l") { Price = 150, Description = "Was that our exit?", Category = VehicleEffects },
        new("Yank the Wheel Right", "sticky_turn_r") { Price = 150, Description = "Was that our exit?", Category = VehicleEffects },
        // new("Invert the Steering", "invert_steering") { Price = 250, Description = "", Category = VehicleEffects },
        // new("Invert the Throttle/Brake", "invert_forward") { Price = 250, Description = "", Category = VehicleEffects },

        new("Change the Camera", "camera_change") { Price = 75, Description = "What were we looking at?", Category = CameraEffects },
        new("Pan the Camera Left", "camera_left") { Price = 25, Description = "This one spins us", Category = CameraEffects },
        new("Pan the Camera Right", "camera_right") { Price = 25, Description = "This one spins us", Category = CameraEffects },
        new("Pan the Camera Up", "camera_up") { Price = 25, Description = "This one spins us", Category = CameraEffects },
        new("Pan the Camera Down", "camera_down") { Price = 25, Description = "This one spins us", Category = CameraEffects },
        new("Zoom the Camera In", "camera_in") { Price = 50, Description = "This brings us closer", Category = CameraEffects },
        new("Zoom the Camera Out", "camera_out") { Price = 50, Description = "This moves us further", Category = CameraEffects },
        new("Reset the Camera", "camera_reset") { Price = 15, Description = "Can we see again?", Category = CameraEffects },
        //new("Mess with the Camera FOV", "camerafov") { Price = 50, Description = "This moves us further", Category = CameraEffects },
        //new("Birthday Dance", "birthday") { Price = 75, Description = "Dance the night away!", Category = CameraEffects },

        new("Set Gravity", "gravity") { Price = 150, Description = "Hope we're not going over a jump", Parameters = GravityParameters, Category = EnvironmentEffects },
        new("Set Simulation scale", "simspeed") { Price = 100, Description = "We need to see that in slow-mo!", Parameters = SimspeedParameters, Category = EnvironmentEffects },
        new("Randomize Fog", "fog") { Price = 100, Description = "Sight is for those who don't want to crash", Category = EnvironmentEffects },
        new("Increase Fog", "fogup") { Price = 40, Description = "Chat says \"We don't want to see\"", Category = EnvironmentEffects },
        new("Decrease Fog", "fogdown") { Price = 40, Description = "Chat says \"Actually can we see\"", Category = EnvironmentEffects },
        new("Set Time to Night", "nighttime") { Price = 25, Description = "Hope you still have headlights", Category = EnvironmentEffects },
        new("Set Time to Day", "daytime") { Price = 25, Description = "FLASHBANG!", Category = EnvironmentEffects },
        new("Set Time to Random", "randomtime") { Price = 25, Description = "We'll get there when we get there", Category = EnvironmentEffects },
        new("Randomize the Day/Night Cycle", "timescale") { Price = 75, Description = "What sort of universe is this?", Category = EnvironmentEffects },
        new("Move Time Forward", "timeforward") { Price = 15, Description = "Some want the future", Category = EnvironmentEffects },
        new("Move Time Backward", "timebackward") { Price = 15, Description = "Some want the past", Category = EnvironmentEffects },

        
        //new("Set AI to Random", "airandom"),
        //new("Anger the AI", "aianger") { Price = 50, Description = "Road rage time" },
        //new("Calm the AI", "aicalm") { Price = 25, Description = "Everyone's a grandma" },
        // new("Make Friends with the AI", "heyai") { Price = 25, Description = "Everyone's a villager?", Category = FunEffects },
        new("Toss a Cone to Your Streamer", "drop_cone") { Price = 5, Description = "Oh Twitch of Plenty", Category = FunEffects },
        new("Drop a Piano", "drop_piano") { Price = 75, Description = "Make some music", Category = FunEffects },
        new("Flock of Birds", "drop_flock") { Price = 500, Description = "Toss some bread crumbs in the back, I heard that attracts lots of birds", Category = FunEffects },
        new("Get a Bus", "drop_bus") { Price = 350, Description = "Looks like that's your bus, better call it over", Category = FunEffects },
        new("Hail a Cab", "drop_taxi") { Price = 175, Description = "TAXI!", Category = FunEffects },
        new("Traffic Jam", "drop_traffic") { Price = 200, Description = "Cause a traffic jam", Category = FunEffects },
        new("Get a Ramp", "drop_ramp") { Price = 200, Description = "Let's jump this thing", Category = FunEffects },
        new("Meteor Shower", "meteors") { Price = 500, Description = "Make a wish! No wait, wrong thing", Category = FunEffects },
        new("Fireworks", "fireworks") { Price = 100, Description = "Celebrate whatever you want!", Category = FunEffects },

        //new("Crowd Control", "cc_effect", ItemKind.Folder
        new("Activate Crowd Control", "cc_activate") { Price = 500, Description = "Take complete control", SessionCooldown = SITimeSpan.FromMinutes(4), Category = CcEffects },
        new("Throttle (1 second)", "cc_throttle_1") { Disabled = true, Group = "cc_effect", Price = 2, Description = "Throttle for one second", Category = CcEffects },
        new("Throttle (3 second)", "cc_throttle_3") { Disabled = true, Group = "cc_effect", Price = 5, Description = "Throttle for three seconds", Category = CcEffects},
        new("Throttle (5 second)", "cc_throttle_5") { Disabled = true, Group = "cc_effect", Price = 10, Description = "Throttle for five seconds", Category = CcEffects },
        new("Straighten Steering", "cc_straight") { Disabled = true, Group = "cc_effect", Price = 10, Description = "Straighten the steering wheel", Category = CcEffects },
        new("Steer Slight Left", "cc_left_1") { Disabled = true, Group = "cc_effect", Price = 10, Description = "Steer slightly left (15 degrees)", Category = CcEffects },
        new("Steer More Left", "cc_left_2") { Disabled = true, Group = "cc_effect", Price = 10, Description = "Steer left (30 degrees)", Category = CcEffects },
        new("Steer Hard Left", "cc_left_3") { Disabled = true, Group = "cc_effect", Price = 10, Description = "Steer left (45 degrees)", Category = CcEffects },
        new("Steer Slight Right", "cc_right_1") { Disabled = true, Group = "cc_effect", Price = 10, Description = "Steer slightly right (15 degrees)", Category = CcEffects },
        new("Steer More Right", "cc_right_2") { Disabled = true, Group = "cc_effect", Price = 10, Description = "Steer right (30 degrees)", Category = CcEffects },
        new("Steer Hard Right", "cc_right_3") { Disabled = true, Group = "cc_effect", Price = 10, Description = "Steer right (45 degrees)", Category = CcEffects },
    };
}

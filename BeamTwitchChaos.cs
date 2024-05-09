using System;
using System.Collections.Generic;
using System.Linq;
using CrowdControl.Common;
using JetBrains.Annotations;
using ConnectorType = CrowdControl.Common.ConnectorType;
using EffectResponse = ConnectorLib.JSON.EffectResponse;
using EffectStatus = CrowdControl.Common.EffectStatus;

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

    public override EffectList Effects { get; } = new Effect[] {
        new("Add a DVD Logo", "dvd") { Price = 15, Description = "Something everyone in chat can watch", Quantity = new QuantityRange(1, 10), DefaultQuantity = 1, Category = new EffectGrouping("UI Effects") },
        new("Add an Ad", "ad") { Price = 15, Description = "You've won a new car!", Quantity = new QuantityRange(1, 10), DefaultQuantity = 1, Category = new EffectGrouping("UI Effects") },
        new("Narrow the Screen", "view_narrow") { Price = 40, Description = "We can see too much, can you do something about that?", Category = new EffectGrouping("UI Effects") },
        new("Squish the Screen", "view_squish") { Price = 40, Description = "We can see too much, can you do something about that?", Category = new EffectGrouping("UI Effects") },
        // new("Shake the Screen", "view_shake") { Price = 80, Description = "Add some drama", Category = new EffectGrouping("UI") },
        new("Clear the Screen", "uireset") { Price = 15, Description = "Can we see again?", Category = new EffectGrouping("UI Effects") },

        new("Pop a Tire", "pop") { Price = 150, Description = "Make it a bit harder to drive", Category = new EffectGrouping("Vehicle Effects") },
        new("Start a Fire", "fire") { Price = 400, Description = "Everyone knows Twitch likes a hot stream", Category = new EffectGrouping("Vehicle Effects") },
        new("Explode", "explode") { Price = 1200, Description = "When the stream is going a little *too* well", Category = new EffectGrouping("Vehicle Effects") },
        new("Extinguish", "extinguish") { Price = 25, Description = "Give the streamer a second chance", Category = new EffectGrouping("Vehicle Effects") },
        new("Ghost", "ghost") { Price = 50, Description = "Invite a ghost to the party", Category = new EffectGrouping("Vehicle Effects") },
        new("Toggle the Ignition", "ignition") { Price = 50, Description = "Jiggle the car keys", Category = new EffectGrouping("Vehicle Effects") },
        new("Set off the Alarm", "alarm") { Price = 50, Description = "I think someone might be trying to break into our car", Category = new EffectGrouping("Vehicle Effects") },
        new("Slam the Car", "slam") { Price = 50, Description = "Slam the car, ZeeKay style", Category = new EffectGrouping("Vehicle Effects") },
        new("Randomize the Paint", "random_paint") { Price = 20, Description = "Let's get some fresh new paint", Category = new EffectGrouping("Vehicle Effects") },
        new("Randomize the Tune", "random_tune") { Price = 200, Description = "I know how to tune, trust me", Category = new EffectGrouping("Vehicle Effects") },
        new("Randomize the Parts", "random_part") { Price = 1000, Description = "Let's order some cool new parts", Category = new EffectGrouping("Vehicle Effects") },
        //new("Damage a Part", "random_damage") { Price = 50, Description = "Give something a break", Category = new EffectGrouping("Vehicle Effects") },
        //new("Repair the Car", "repair") { Price = 50, Description = "Nothing a bit of percussive maintenance can't fix", Category = new EffectGrouping("Vehicle Effects") },
        new("Turn on the Forcefield", "forcefield") { Price = 75, Description = "Push everything away", Category = new EffectGrouping("Vehicle Effects") },
        new("Turn on the Negative Forcefield", "attractfield") { Price = 250, Description = "Pull everything in", Category = new EffectGrouping("Vehicle Effects") },
        new("Turn Around (Fast)", "spin") { Price = 200, Description = "I think we're going the wrong way", Category = new EffectGrouping("Vehicle Effects") },
        new("Bump the Car Left", "nudge_l") { Price = 50, Description = "Give it a bit of a push", Category = new EffectGrouping("Vehicle Effects") },
        new("Bump the Car Right", "nudge_r") { Price = 50, Description = "Give it a bit of a push", Category = new EffectGrouping("Vehicle Effects") },
        new("Kick the Car Left", "kick_l") { Price = 175, Description = "Ok now you might be going too far", Category = new EffectGrouping("Vehicle Effects") },
        new("Kick the Car Right", "kick_r") { Price = 175, Description = "Ok now you might be going too far", Category = new EffectGrouping("Vehicle Effects") },
        new("Jump the Car", "jump_l") { Price = 100, Description = "Woah, sick jump!", Category = new EffectGrouping("Vehicle Effects") },
        new("Jump the Car Really High", "jump_h") { Price = 300, Description = "Hang on, are you a superhero?!", Category = new EffectGrouping("Vehicle Effects") },
        new("Tilt the Car Left", "tilt_l") { Price = 100, Description = "What's better than cow tipping?", Category = new EffectGrouping("Vehicle Effects") },
        new("Tilt the Car Right", "tilt_r") { Price = 100, Description = "What's better than cow tipping?", Category = new EffectGrouping("Vehicle Effects") },
        new("Do a Barrel Roll Left", "roll_l") { Price = 300, Description = "Ackshually it's not a barrel roll", Category = new EffectGrouping("Vehicle Effects") },
        new("Do a Barrel Roll Right", "roll_r") { Price = 300, Description = "Ackshually it's not a barrel roll", Category = new EffectGrouping("Vehicle Effects") },
        new("Give a Small Boost", "boost_l") { Price = 50, Description = "Is this one of those video games?", Category = new EffectGrouping("Vehicle Effects") },
        new("Rocket Boost", "boost_h") { Price = 200, Description = "Time to go Sonic Fast", Category = new EffectGrouping("Vehicle Effects") },
        new("Do a Kickflip", "kickflip") { Price = 350, Description = "Did you know you look a lot like Tony Hawk?", Category = new EffectGrouping("Vehicle Effects") },
        //new("Skip the Car", "skip") { Price = 100, Description = "Skipping is a healthy way to move around", Category = new EffectGrouping("Vehicle Effects") },
        new("Sticky Throttle", "sticky_throttle") { Price = 125, Description = "Onward!", Category = new EffectGrouping("Vehicle Effects") },
        new("Sticky Handbrake", "sticky_parkingbrake") { Price = 125, Description = "Do a drift!", Category = new EffectGrouping("Vehicle Effects") },
        new("Sticky Brake", "sticky_brake") { Price = 75, Description = "We're going too fast!", Category = new EffectGrouping("Vehicle Effects") },
        new("Yank the Wheel Left", "sticky_turn_l") { Price = 150, Description = "Was that our exit?", Category = new EffectGrouping("Vehicle Effects") },
        new("Yank the Wheel Right", "sticky_turn_r") { Price = 150, Description = "Was that our exit?", Category = new EffectGrouping("Vehicle Effects") },
        // new("Invert the Steering", "invert_steering") { Price = 250, Description = "", Category = new EffectGrouping("Vehicle Effects") },
        // new("Invert the Throttle/Brake", "invert_forward") { Price = 250, Description = "", Category = new EffectGrouping("Vehicle Effects") },

        new("Change the Camera", "camera_change") { Price = 75, Description = "What were we looking at?", Category = new EffectGrouping("Camera Effects") },
        new("Pan the Camera Left", "camera_left") { Price = 25, Description = "This one spins us", Category = new EffectGrouping("Camera Effects") },
        new("Pan the Camera Right", "camera_right") { Price = 25, Description = "This one spins us", Category = new EffectGrouping("Camera Effects") },
        new("Pan the Camera Up", "camera_up") { Price = 25, Description = "This one spins us", Category = new EffectGrouping("Camera Effects") },
        new("Pan the Camera Down", "camera_down") { Price = 25, Description = "This one spins us", Category = new EffectGrouping("Camera Effects") },
        new("Zoom the Camera In", "camera_in") { Price = 50, Description = "This brings us closer", Category = new EffectGrouping("Camera Effects") },
        new("Zoom the Camera Out", "camera_out") { Price = 50, Description = "This moves us further", Category = new EffectGrouping("Camera Effects") },
        new("Reset the Camera", "camera_reset") { Price = 15, Description = "Can we see again?", Category = new EffectGrouping("Camera Effects") },
        //new("Mess with the Camera FOV", "camerafov") { Price = 50, Description = "This moves us further", Category = new EffectGrouping("Camera Effects") },
        //new("Birthday Dance", "birthday") { Price = 75, Description = "Dance the night away!", Category = new EffectGrouping("Camera Effects") },

        new("Set Gravity", "gravity") { Price = 150, Description = "Hope we're not going over a jump", Parameters = GravityParameters, Category = new EffectGrouping("Environment Effects") },
        new("Set Simulation scale", "simspeed") { Price = 100, Description = "We need to see that in slow-mo!", Parameters = SimspeedParameters, Category = new EffectGrouping("Environment Effects") },
        new("Randomize Fog", "fog") { Price = 100, Description = "Sight is for those who don't want to crash", Category = new EffectGrouping("Environment Effects") },
        new("Increase Fog", "fogup") { Price = 40, Description = "Chat says \"We don't want to see\"", Category = new EffectGrouping("Environment Effects") },
        new("Decrease Fog", "fogdown") { Price = 40, Description = "Chat says \"Actually can we see\"", Category = new EffectGrouping("Environment Effects") },
        new("Set Time to Night", "nighttime") { Price = 25, Description = "Hope you still have headlights", Category = new EffectGrouping("Environment Effects") },
        new("Set Time to Day", "daytime") { Price = 25, Description = "FLASHBANG!", Category = new EffectGrouping("Environment Effects") },
        new("Set Time to Random", "randomtime") { Price = 25, Description = "We'll get there when we get there", Category = new EffectGrouping("Environment Effects") },
        new("Randomize the Day/Night Cycle", "timescale") { Price = 75, Description = "What sort of universe is this?", Category = new EffectGrouping("Environment Effects") },
        new("Move Time Forward", "timeforward") { Price = 15, Description = "Some want the future", Category = new EffectGrouping("Environment Effects") },
        new("Move Time Backward", "timebackward") { Price = 15, Description = "Some want the past", Category = new EffectGrouping("Environment Effects") },

        
        //new("Set AI to Random", "airandom"),
        //new("Anger the AI", "aianger") { Price = 50, Description = "Road rage time" },
        //new("Calm the AI", "aicalm") { Price = 25, Description = "Everyone's a grandma" },
        // new("Make Friends with the AI", "heyai") { Price = 25, Description = "Everyone's a villager?", Category = new EffectGrouping("Fun Effects") },
        new("Toss a Cone to Your Streamer", "drop_cone") { Price = 10, Description = "Oh Twitch of Plenty", Category = new EffectGrouping("Fun Effects") },
        new("Drop a Piano", "drop_piano") { Price = 100, Description = "Make some music", Category = new EffectGrouping("Fun Effects") },
        new("Flock of Birds", "drop_flock") { Price = 500, Description = "Toss some bread crumbs in the back, I heard that attracts lots of birds", Category = new EffectGrouping("Fun Effects") },
        new("Get a Bus", "drop_bus") { Price = 300, Description = "Looks like that's your bus, better call it over", Category = new EffectGrouping("Fun Effects") },
        new("Hail a Cab", "drop_taxi") { Price = 200, Description = "TAXI!", Category = new EffectGrouping("Fun Effects") },
        new("Traffic Jam", "drop_traffic") { Price = 500, Description = "Cause a traffic jam", Category = new EffectGrouping("Fun Effects") },
        new("Get a Ramp", "drop_ramp") { Price = 250, Description = "Let's jump this thing", Category = new EffectGrouping("Fun Effects") },

        // new("Crowd Control Effects", "cc_effect", ItemKind.Folder),
        // new("Throttle (1 second)", "cc_throttle_1", "cc_effect") { Price = 2, Description = "Throttle for one second" },
        // new("Throttle (3 second)", "cc_throttle_3", "cc_effect") { Price = 5, Description = "Throttle for three seconds" },
        // new("Throttle (5 second)", "cc_throttle_5", "cc_effect") { Price = 10, Description = "Throttle for three seconds" },
    };
}

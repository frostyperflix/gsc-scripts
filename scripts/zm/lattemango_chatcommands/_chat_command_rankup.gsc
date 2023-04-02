// Developed by lattemango

#include scripts\chat_commands;

#include scripts\zm\lattemango_chatcommands\util\_database;
#include scripts\zm\lattemango_chatcommands\util\_debugprint;
#include scripts\zm\lattemango_chatcommands\util\_error;
#include scripts\zm\lattemango_chatcommands\util\_tostring;

// Used with set_map_stat(), get_map_stat()
#include maps\mp\zombies\_zm_stats;
// Used with do_player_general_vox()
#include maps\mp\zombies\_zm_utility;

rankup(levels)
{
    if (levels <= 0)
    {
        return;
    }

    // You can do all kinds of math to calculate the fee for ranking up per level.
    rankupFee = (levels * (self.pers["account_rank"] * 2000));

    // Making sure the player has the money either in the bank or in their score.
    if (self.pers["account_bank"] < rankupFee && self.score < rankupFee)
    {
        self thread do_player_general_vox("general", "exert_sigh", 10, 50);
        self tell("You don't have enough points! ^2Rank " + (self.pers["account_rank"] + levels) + "^7 requires ^1" + rankupFee + "^7 points!");
        return;
    }

    self playsoundtoplayer("zmb_vault_bank_withdraw", self);

    // If the player has the points to rankup, then use those, otherwise use the bank.
    if (self.score >= rankupFee)
    {
        self.score -= rankupFee;
    }
    else if (self.pers["account_bank"] >= rankupFee)
    {
        self.pers["account_bank"] -= rankupFee;
        self.account_value = (self.pers["account_bank"] / 1000);
        // Set the player's physical bank stats to the chat bank.
        self set_map_stat("depositBox", self.account_value);
    }
    else
    {
        // No one should realisticly be able to get here!
        return;
    }

    // Update player rank!
    self.pers["account_rank"] += levels;
    self database_update_playerdata();

    self tell("^6You^7 are now ^2Rank " + self.pers["account_rank"] + "^7 (Fee:^1 " + rankupFee + "^7)");
}

rankupCommand(args)
{
    // If we are not debugging, then don't display command hints.
    debug = level.pers["chat_command_hints"];
    if (!(isDefined(debug) && debug))
    {
        if (!isDefined(args[0]))
        {
            rankup(1);
        }
        else
        {
            rankup(args[0]);
        }
        return;
    }

    // Command error checking.
    if (args.size > 1) { return TooManyArgsError(1); }
    if (args.size < 1) { error = rankup(1); }
    else { error = rankup(args[0]); }
    if (IsDefined(error)) { return error; }
}

rank()
{
    self tell("^6You^7 are ^2Rank " + self.pers["account_rank"] + "^7.");
}

rankCommand(args)
{
    // If we are not debugging, then don't display command hints.
    debug = level.pers["chat_command_hints"];
    if (!(isDefined(debug) && debug))
    {
        rank();
        return;
    }

    // Command error checking.
    if (args.size > 0) { return; }
    error = rank();
    if (IsDefined(error)) { return error; }
}

init()
{
    // Create the chat commands here.
    CreateCommand(level.chat_commands["ports"], "rank", "function", ::rankCommand, 3);
    CreateCommand(level.chat_commands["ports"], "r", "function", ::rankCommand, 3);

    CreateCommand(level.chat_commands["ports"], "rankup", "function", ::rankupCommand, 3);
    CreateCommand(level.chat_commands["ports"], "rup", "function", ::rankupCommand, 3);

    printf("Executed \'scripts/zm/lattemango_chatcommands/_chat_command_rankup::init\'");
}

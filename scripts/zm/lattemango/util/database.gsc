// Developed by lattemango!

// My utility classes.
#include scripts\zm\lattemango\util\debugprintf;
#include scripts\zm\lattemango\util\mapname;
#include scripts\zm\lattemango\util\type;

statstrings_account_get()
{
    return array("account_bank", "account_name", "account_rank", "account_records");
}

// The purpose of this function is to read from the json database and return it as usable data.
database_get()
{
    debugprintf("DATABASE", "^2GET");

    database_struct = readfile(level.server_data["database_path"]);
    return jsonParse(database_struct);
}

// The purpose of this function is to set the database file with the struct provided.
database_set(database_struct)
{
    debugprintf("DATABASE", "^2SET");

    writefile(level.server_data["database_path"], jsonserialize(database_struct, 4));
}

database_backup()
{
    backup_path = (level.server_data["path"] + "/backups");
    database_path = level.server_data["database_path"];

    if (!fileexists(database_path) || filesize(database_path) == 0)
    {
        debugprintf("DATABASE", "^1BACKUP DATABASE_NOT_FOUND");
        return;
    }

    data = readfile(database_path);

    if (!directoryexists(backup_path))
    {
        createdirectory(backup_path);
    }

    backups = listfiles(backup_path);
    if ((backups.size + 1) > 20)
    {
        foreach (file in backups)
        {
            fremove(file);
        }
    }

    writefile((backup_path + "/database_backup_" + (backups.size + 1) + ".json"), data);
}

database_cache_get()
{
    debugprintf("DATABASE::CACHE", "^2GET");

    return level.server_data["database_cache"];
}

// The purpose of this function is to set the database cache with the struct provided.
database_cache_set(database_struct)
{
    debugprintf("DATABASE::CACHE", "^2SET");

    level.server_data["database_cache"] = database_struct;
}

// The purpose of this function is to read from the database.json file and set the cache.
database_cache_update()
{
    debugprintf("DATABASE::CACHE", "^2UPDATE");

    database_struct = database_get();
    database_cache_set(database_struct);
}

// The purpose of this function is to return the playerdata from the database.
database_playerdata_get()
{
    debugprintf("DATABASE::PLAYERDATA", "^2GET");

    return database_get()["players"][type_tostring(self getguid())];
}

// The point of this function is to set the player's data specifically.
database_playerdata_update()
{
    debugprintf("DATABASE::PLAYERDATA", "^2SET");

    database = database_get();
    playerdata = database_playerdata_get();

    stats = statstrings_account_get();
    foreach (stat in stats)
    {
        playerdata[stat] = self.pers[stat];
    }

    database["players"][type_tostring(self getGuid())] = playerdata;
    database_set(database);
}

database_playerdata_new(guid)
{
    guid = type_tostring(guid);
    playerdata = [];

    playerdata["players"][guid]["account_name"] = "";
    playerdata["players"][guid]["account_bank"] = 0;
    playerdata["players"][guid]["account_rank"] = 1;

    account_records = mapname_get_all();
    foreach (map in account_records)
    {
        playerdata["players"][guid]["account_records"][map] = 0;
    }

    return playerdata;
}

database_cache_playerdata_get()
{
    debugprintf("DATABASE::CACHE::PLAYERDATA", "^2GET");

    database_cache_struct = database_cache_get();
    return database_cache_struct["players"][type_tostring(self getguid())];
}

database_cache_playerdata_update()
{
    debugprintf("DATABASE::CACHE::PLAYERDATA", "^2SET");

    database = database_cache_get();
    playerdata = database_cache_playerdata_get();

    stats = statstrings_account_get();
    foreach (stat in stats)
    {
        playerdata[stat] = self.pers[stat];
    }

    database["players"][type_tostring(self getGuid())] = playerdata;
    database_cache_set(database);
}

// The purpose of this function is to return the recorddata for this map from the database.
database_recorddata_get()
{
    debugprintf("DATABASE::RECORDDATA", "^2GET");

    database_struct = database_get();
    return database_struct["records"][mapname_get()];
}

// The point of this function is to update the server's record data specifically.
database_recorddata_update()
{
    debugprintf("DATABASE::RECORDDATA", "^2UPDATE");

    database = database_get();

    record_set_by = "";
    for (i = 0; i < level.players.size; i++)
    {
        record_set_by += level.players[i].pers["account_name"];

        if ((i + 1) != level.players.size)
        {
            record_set_by += ", ";
        }
    }

    recorddata = database_recorddata_get();
    recorddata["record"] = level.round_number;
    recorddata["record_set_by"] = record_set_by;

    database["records"][mapname_get()] = recorddata;
    database_set(database);
}

database_recorddata_new()
{
    recorddata = [];

    record = [];
    record["record"] = 0;
    record["record_set_by"] = "";

    server_records = mapname_get_all();
    foreach (map in server_records)
    {
        recorddata["records"][map] = record;
    }
    return recorddata;
}

database_cache_recorddata_get()
{
    debugprintf("DATABASE::CACHE::RECORDDATA", "^2GET");

    database_cache_struct = database_cache_get();
    return database_cache_struct["records"][mapname_get()];
}

database_cache_recorddata_update()
{
    debugprintf("DATABASE::CACHE::RECORDDATA", "^2UPDATE");

    database = database_cache_get();

    record_set_by = "";
    for (i = 0; i < level.players.size; i++)
    {
        record_set_by += level.players[i].pers["account_name"];

        if ((i + 1) != level.players.size)
        {
            record_set_by += ", ";
        }
    }

    recorddata = database_cache_recorddata_get();
    recorddata["record"] = level.round_number;
    recorddata["record_set_by"] = record_set_by;

    database["records"][mapname_get()] = recorddata;
    database_cache_set(database);
}

// The goal of database_initialise is to make sure database.json exists
database_init()
{
    path = level.server_data["database_path"];

    if (fileexists(path))
    {
        data = type_tostring(readfile(path));
        if (!(data == "" || data == " " || data == "null" || filesize(path) == 0))
        {
            database_cache_update();
            debugprintf("DATABASE::INIT", "^2SUCCESS");
            return;
        }
    }

    debugprintf("DATABASE::INIT", "^3NOT_FOUND CREATING_NEW");

    // If the database doesn't exist, we retry infinitely until we can make it exist.
    while(!fileexists(path))
    {
        writefile(path, "");
        wait 1;
    }

    debugprintf("DATABASE::INIT", "^2WRITE_DEFAULTS");

    defaultdata = database_playerdata_new(0);
    defaultdata["records"] = database_recorddata_new()["records"];

    // Open the file we just created and initialise it with default JSON data.
    writefile(path, jsonserialize(defaultdata, 4));

    database_cache_update();
    debugprintf("DATABASE::INIT", "^2SUCCESS");
}

// The purpose of this function is to init the player entity's data from the database.
database_initplayer()
{
    playerdata = self database_playerdata_get();

    if (!isdefined(playerdata))
    {
        debugprintf("DATABASE::INITPLAYER", "^3NOT_FOUND CREATING_NEW");

        guid = type_tostring(self getguid());

        database = database_get();
        database["players"][guid] = database_playerdata_new(guid)["players"][guid];
        database_set(database);

        playerdata = database["players"][guid];

        debugprintf("DATABASE::INITPLAYER", "^2PLAYERDATA SUCCESS");
    }

    stats = statstrings_account_get();
    foreach (stat in stats)
    {
        self.pers[stat] = playerdata[stat];
    }
    self.pers["account_name"] = self.name;

    // Set this so the player can't use their in game bank to essentially 'duplicate' their money.
    self.account_value = (self.pers["account_bank"] / 1000);

    debugprintf("DATABASE::INITPLAYER", "^2SUCCESS");
}

database_cache_initplayer()
{
    self endon("disconnect");

    playerdata = self database_cache_playerdata_get();

    if (!isdefined(playerdata))
    {
        debugprintf("DATABASE::CACHE::INITPLAYER", "^3NOT_FOUND CREATING_NEW");
        
        guid = type_tostring(self getguid());

        database = database_cache_get();
        database["players"][guid] = database_playerdata_new(guid)["players"][guid];
        database_cache_set(database);

        playerdata = database["players"][guid];

        debugprintf("DATABASE::CACHE::INITPLAYER", "^2PLAYERDATA SUCCESS");
    }

    stats = statstrings_account_get();
    foreach (stat in stats)
    {
        self.pers[stat] = playerdata[stat];
    }
    self.pers["account_name"] = self.name;

    // Set this so the player can't use their in game bank to essentially 'duplicate' their money.
    self.account_value = (self.pers["account_bank"] / 1000);

    debugprintf("DATABASE::CACHE::INITPLAYER", "^2SUCCESS");
}

on_player_connect()
{
    for (;;)
    {
        level waittill("connected", player);
        player thread database_cache_initplayer();
    }
}

on_game_end()
{
    for (;;)
    {
        level waittill("record_update_done");

        database_cache_struct = database_cache_get();
        database_set(database_cache_struct);

        database_backup();
    }
}

init()
{
    level.server_data["path"] = "server_data";
    level.server_data["database_path"] = level.server_data["path"] + "/database.json";
    level.server_data["database_cache"] = [];

    database_init();
    level thread on_player_connect();
    level thread on_game_end();
}

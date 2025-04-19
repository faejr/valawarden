namespace LibUUID {
    public static string uuid_generate () {
        uint8 time[16];
        char uuid[37];

        generate_random (time);
        unparse (time, uuid);

        return (string) uuid;
    }
}
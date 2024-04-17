public  class PhoneValidatorRegex {
    
    public static final Map<String, String> REGEX_PATTERNS = new Map<String, String>{
        'LEADING_DUBBEL_ZERO' => '^0046\\d{9}$',
        'LEADING_COUNTRY_CODE' => '^46\\d{9}$',
        'STARTING_SEVEN' => '^7\\d{8}$'
    };

    public static final Map<String, String> REGEX_FIND = new Map<String, String>{
        'LEADING_DUBBEL_ZERO' => '^0046',
        'LEADING_COUNTRY_CODE' => '^46',
        'STARTING_SEVEN' => '^'
    };

    public static final Map<String, String> REGEX_SUB = new Map<String, String>{
        'LEADING_DUBBEL_ZERO' => '0',
        'LEADING_COUNTRY_CODE' => '0',
        'STARTING_SEVEN' => '0'
    };
}
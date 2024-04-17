public class PhoneValidatorUtil {

    /**
     * Sets MC phone on Contact, if no match then return empty
     */
    public static String generateFormatedPhoneNumber(String phoneNumber){
        //Order in list is of importance, first match of valid phone is returned
        String phoneNr = cleanPhoneNr(phoneNumber);
        String regexMatch = matchRegex(phoneNr);
        if(regexMatch != null){
            String formatedPhone = formatPhoneNr(phoneNr, regexMatch);
            return formatedPhone;
        }
        return phoneNumber;

    }

    public static String cleanPhoneNr(String phoneNr){
        if(phoneNr != null){
            phoneNr = removeSpecialChar(phoneNr);
            phoneNr = removeWhiteSpace(phoneNr);
            return phoneNr;
        }
        return null;
    }

    public static String removeWhiteSpace(String phoneNr){
        Pattern p = Pattern.compile('\\s');
        Matcher pm = p.matcher(phoneNr);
        if(pm.find()){
            return pm.replaceAll('');
        }
        return phoneNr;
    }

    public static String removeSpecialChar(String phoneNr){
        Pattern p = Pattern.compile('\\D');
        Matcher pm = p.matcher(phoneNr);
        if(pm.find()){
            return pm.replaceAll('');
        }
        return phoneNr;
    }

    /**
     * Check if phone matches any regex pattern
     * Return true if yes
     */
    public static Boolean isValidPhoneNr(String phoneNr, String regexPattern){
        if(phoneNr == null){
            return false;
        }
        String regex = PhoneValidatorRegex.REGEX_PATTERNS.get(regexPattern);
        Pattern p = Pattern.compile(regex);
        Matcher pm = p.matcher(phoneNr);
        if(pm.matches()){
            return true;
        }
        return false;
    }

    /**
     * Returns regex pattern if match is found
     */
    public static String matchRegex(String phoneNr){
        for(String regexPattern: PhoneValidatorRegex.REGEX_PATTERNS.keySet()){
            Boolean isValid = isValidPhoneNr(phoneNr, regexPattern);
            if(isValid){
                return regexPattern;
            }
        }
        return null;
    }

    /**
     * formats phone number using matching regex pattern
     */
    public static String formatPhoneNr(String phoneNr, String regexPattern){
        String findPattern = PhoneValidatorRegex.REGEX_FIND.get(regexPattern);
        String replacePattern = PhoneValidatorRegex.REGEX_SUB.get(regexPattern);
        return phoneNr.replaceAll(findPattern, replacePattern);
    }




}
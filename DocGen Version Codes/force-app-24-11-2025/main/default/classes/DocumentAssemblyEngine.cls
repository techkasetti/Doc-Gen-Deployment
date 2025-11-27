/**
 * @description The core engine that merges a template string with JSON data.
 * Supports simple merge fields, conditional blocks, and loops.
 */
public class DocumentAssemblyEngine {

    public static String assemble(String templateBody, String jsonData) {
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
        String result = templateBody;

        // 1. Process Loops First (to handle nested merge fields)
        result = processLoops(result, data);

        // 2. Process Conditionals
        result = processConditionals(result, data);
        
        // 3. Process Simple Merge Fields
        result = processMergeFields(result, data);

        return result;
    }

    /**
     * @description Processes {{#each listName}}...{{/each}} blocks.
     */
    private static String processLoops(String text, Map<String, Object> data) {
        String loopRegex = '(?s)\\{\\{#each (.*?)\\}\\}(.*?)\\{\\{/each\\}\\}';
        Matcher m = Pattern.compile(loopRegex).matcher(text);

        while (m.find()) {
            String fullMatch = m.group(0);
            String listPath = m.group(1);  // e.g., Opportunity.LineItems
            String innerBlock = m.group(2);

            Object listObject = getValueFromPath(data, listPath);
            
            // CORRECTED: Use a standard String, not StringBuilder
            String renderedBlock = '';

            if (listObject instanceof List<Object>) {
                for (Object item : (List<Object>)listObject) {
                    if (item instanceof Map<String, Object>) {
                        // For each item in the list, process the inner block
                        renderedBlock += processMergeFields(innerBlock, (Map<String, Object>)item, 'this.');
                    }
                }
            }
            text = text.replace(fullMatch, renderedBlock);
        }
        return text;
    }

    /**
     * @description Processes {{#if condition}}...{{/if}} blocks.
     */
    private static String processConditionals(String text, Map<String, Object> data) {
        String conditionalRegex = '(?s)\\{\\{#if (.*?)\\}\\}(.*?)\\{\\{/if\\}\\}';
        Matcher m = Pattern.compile(conditionalRegex).matcher(text);

        while (m.find()) {
            String fullMatch = m.group(0);
            String conditionPath = m.group(1);
            String innerBlock = m.group(2);

            Object value = getValueFromPath(data, conditionPath);
            Boolean conditionMet = (value != null && value != false && value != '');
            
            text = text.replace(fullMatch, conditionMet ? innerBlock : '');
        }
        return text;
    }

    /**
     * @description Processes simple {{Object.Field}} merge fields within a loop.
     */
    private static String processMergeFields(String text, Map<String, Object> data, String prefix) {
        String mergeFieldRegex = '\\{\\{(.*?)\\}\\}';
        Matcher m = Pattern.compile(mergeFieldRegex).matcher(text);

        while (m.find()) {
            String fullMatch = m.group(0);
            String fieldPath = m.group(1);

            if (fieldPath.startsWith(prefix)) {
                // It's a field inside a loop item, e.g. {{this.Price}}
                Object value = getValueFromPath(data, fieldPath.removeStart(prefix));
                text = text.replace(fullMatch, String.valueOf(value == null ? '' : value));
            }
        }
        return text;
    }

    /**
     * @description Processes simple {{Object.Field}} merge fields.
     */
    private static String processMergeFields(String text, Map<String, Object> data) {
        String mergeFieldRegex = '\\{\\{(.*?)\\}\\}';
        Matcher m = Pattern.compile(mergeFieldRegex).matcher(text);

        while (m.find()) {
            String fullMatch = m.group(0);
            String fieldPath = m.group(1);
            Object value = getValueFromPath(data, fieldPath);
            text = text.replace(fullMatch, String.valueOf(value == null ? '' : value));
        }
        return text;
    }

    // Helper to navigate JSON map using dot notation (e.g., "Account.Name")
    private static Object getValueFromPath(Map<String, Object> data, String path) {
        List<String> keys = path.split('\\.');
        Object currentObject = data;
        for (String key : keys) {
            if (currentObject instanceof Map<String, Object>) {
                currentObject = ((Map<String, Object>)currentObject).get(key);
            } else {
                return null;
            }
        }
        return currentObject;
    }
}
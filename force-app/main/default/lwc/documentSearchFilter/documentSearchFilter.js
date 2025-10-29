import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import searchDocuments from '@salesforce/apex/DocumentSearchController.searchDocuments';
import getFilterOptions from '@salesforce/apex/DocumentSearchController.getFilterOptions';

export default class DocumentSearchFilter extends LightningElement {
    @api recordId;
    @track searchTerm = '';
    @track searchResults = [];
    @track isLoading = false;
    @track hasActiveFilters = false;
    @track activeFilters = [];

    @track filters = {
        createdFromDate: null,
        createdToDate: null,
        fileType: '',
        gdprCompliance: '',
        hipaaCompliance: '',
        fileSize: '',
        contentClassification: '',
        minComplianceScore: 0,
        aiQuery: ''
    };

    // Options for dropdown filters
    fileTypeOptions = [
        { label: 'All Types', value: '' },
        { label: 'PDF', value: 'pdf' },
        { label: 'Word Document', value: 'docx' },
        { label: 'Excel', value: 'xlsx' },
        { label: 'PowerPoint', value: 'pptx' },
        { label: 'Text', value: 'txt' },
        { label: 'HTML', value: 'html' }
    ];

    complianceOptions = [
        { label: 'Any Status', value: '' },
        { label: 'Compliant', value: 'true' },
        { label: 'Non-Compliant', value: 'false' },
        { label: 'Not Analyzed', value: 'null' }
    ];

    fileSizeOptions = [
        { label: 'Any Size', value: '' },
        { label: 'Small (< 1MB)', value: 'small' },
        { label: 'Medium (1-10MB)', value: 'medium' },
        { label: 'Large (10-100MB)', value: 'large' },
        { label: 'Very Large (> 100MB)', value: 'xlarge' }
    ];

    classificationOptions = [
        { label: 'All Classifications', value: '' },
        { label: 'Legal Document', value: 'LEGAL' },
        { label: 'Financial Document', value: 'FINANCIAL' },
        { label: 'Healthcare Document', value: 'HEALTHCARE' },
        { label: 'Personal Data', value: 'PERSONAL_DATA' },
        { label: 'Confidential', value: 'CONFIDENTIAL' },
        { label: 'Public', value: 'PUBLIC' }
    ];

    connectedCallback() {
        this.loadFilterOptions();
    }

    async loadFilterOptions() {
        try {
            const options = await getFilterOptions();
            // Update options based on server response if needed
            this.updateFilterOptions(options);
        } catch (error) {
            console.error('Error loading filter options:', error);
        }
    }

    updateFilterOptions(options) {
        if (options.fileTypes) {
            this.fileTypeOptions = [
                { label: 'All Types', value: '' },
                ...options.fileTypes.map(type => ({
                    label: type.toUpperCase(),
                    value: type
                }))
            ];
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        // Debounce search
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.performSearch();
        }, 500);
    }

handleFilterChange(event) {
    const field = event.target.dataset.field || event.target.name;
    let value = event.target.value;
    
    // Handle different input types
    if (event.target.type === 'checkbox') {
        value = event.target.checked;
    }
    
    // Update filters object
    this.filters = { ...this.filters, [field]: value };
    
    // Update active filters display
    this.updateActiveFilters();
}

handleApplyFilters() {
    this.performSearch();
}

handleClearFilters() {
    this.filters = {
        createdFromDate: null,
        createdToDate: null,
        fileType: '',
        gdprCompliance: '',
        hipaaCompliance: '',
        fileSize: '',
        contentClassification: '',
        minComplianceScore: 0,
        aiQuery: ''
    };
    
    this.activeFilters = [];
    this.hasActiveFilters = false;
    this.searchTerm = '';
    
    // Clear search results
    this.searchResults = [];
    
    // Dispatch event to parent component
    this.dispatchEvent(new CustomEvent('filterscleared', {
        detail: { filters: this.filters, searchTerm: this.searchTerm }
    }));
}

handleRemoveFilter(event) {
    const fieldToRemove = event.target.name;
    
    // Reset the specific filter
    if (fieldToRemove === 'minComplianceScore') {
        this.filters[fieldToRemove] = 0;
    } else {
        this.filters[fieldToRemove] = '';
    }
    
    // Update active filters
    this.updateActiveFilters();
    
    // Perform new search
    this.performSearch();
}

updateActiveFilters() {
    this.activeFilters = [];
    
    // Check each filter and add to active list if it has a value
    Object.keys(this.filters).forEach(key => {
        const value = this.filters[key];
        if (value && value !== '' && value !== null && value !== 0) {
            let label = this.getFilterLabel(key, value);
            this.activeFilters.push({
                id: key,
                field: key,
                label: label
            });
        }
    });
    
    this.hasActiveFilters = this.activeFilters.length > 0;
}

getFilterLabel(field, value) {
    const labelMap = {
        createdFromDate: `From: ${value}`,
        createdToDate: `To: ${value}`,
        fileType: `Type: ${value.toUpperCase()}`,
        gdprCompliance: `GDPR: ${value === 'true' ? 'Compliant' : 'Non-Compliant'}`,
        hipaaCompliance: `HIPAA: ${value === 'true' ? 'Compliant' : 'Non-Compliant'}`,
        fileSize: `Size: ${value}`,
        contentClassification: `Classification: ${value}`,
        minComplianceScore: `Min Score: ${value}%`,
        aiQuery: `AI Query: ${value}`
    };
    
    return labelMap[field] || `${field}: ${value}`;
}

async performSearch() {
    if (!this.searchTerm && !this.hasActiveFilters) {
        return;
    }
    
    this.isLoading = true;
    
    try {
        const searchParams = {
            searchTerm: this.searchTerm,
            filters: this.filters
        };
        
        const results = await searchDocuments({ searchParams: searchParams });
        this.searchResults = results;
        
        // Dispatch search results to parent
        this.dispatchEvent(new CustomEvent('searchcomplete', {
            detail: {
                results: results,
                searchTerm: this.searchTerm,
                filters: this.filters
            }
        }));
        
    } catch (error) {
        console.error('Search error:', error);
        this.showToast('Error', 'Search failed: ' + error.body.message, 'error');
    } finally {
        this.isLoading = false;
    }
}

showToast(title, message, variant) {
    const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    });
    this.dispatchEvent(event);
}

// Getter for search button disabled state
get isSearchDisabled() {
    return this.isLoading || (!this.searchTerm && !this.hasActiveFilters);
}
}
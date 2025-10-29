import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import getGeneratedDocuments from '@salesforce/apex/DocumentSaveController.getGeneratedDocuments';
import getGenerationAnalytics from '@salesforce/apex/DocumentGenerationAnalytics.getGenerationAnalytics';
import exportAnalyticsReport from '@salesforce/apex/DocumentGenerationAnalytics.exportAnalyticsReport';
import regenerateDocument from '@salesforce/apex/DocumentSaveController.regenerateDocument';
import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';

// Table Columns
const DOCUMENT_COLUMNS = [
    { label: 'Document Title', fieldName: 'title', type: 'text', sortable: true },
    {
        label: 'Created Date',
        fieldName: 'createdDate',
        type: 'date-local',
        sortable: true,
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    { label: 'File Type', fieldName: 'fileType', type: 'text' },
    { label: 'AI Generated', fieldName: 'aiGenerated', type: 'boolean' },
    { label: 'AI Model', fieldName: 'aiModel', type: 'text' },
    { label: 'Template', fieldName: 'templateName', type: 'text' },
    {
        label: 'Size (KB)',
        fieldName: 'sizeKB',
        type: 'number',
        typeAttributes: { maximumFractionDigits: 1 }
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'View', name: 'view' },
                { label: 'Regenerate', name: 'regenerate' },
                { label: 'Download', name: 'download' },
                { label: 'Delete', name: 'delete' }
            ]
        }
    }
];

export default class DocumentCollectionManager extends NavigationMixin(LightningElement) {
    @api recordId; // Folder ID

    @track documents = [];
    @track filteredDocuments = [];
    @track analytics = {};
    @track contextAnalysis = null;

    // UI State
    @track showAnalytics = false;
    @track showContextModal = false;
    @track isAnalyzing = false;
    @track isLoading = false;

    // Filters and Search
    @track searchTerm = '';
    @track selectedFilter = '';
    @track sortedBy = 'createdDate';
    @track sortDirection = 'desc';

    // Chart references
    chartInstance;
    modelChartInstance;

    // Computed properties
    @track documentCount = 0;
    @track aiGeneratedCount = 0;
    @track contextQualityScore = 0;
    @track avgGenerationTime = 0;

    documentColumns = DOCUMENT_COLUMNS;
    wiredDocumentsResult;

    // ----------------- LIFECYCLE -----------------
    connectedCallback() {
        this.loadDocuments();
        this.loadAnalytics();
    }

    @wire(getGeneratedDocuments, { folderId: '$recordId' })
    wiredDocuments(result) {
        this.wiredDocumentsResult = result;
        if (result.data) {
            this.processDocuments(result.data);
        } else if (result.error) {
            this.showToast('Error', 'Failed to load documents', 'error');
        }
    }

    // ----------------- DATA PROCESSING -----------------
    processDocuments(documents) {
        this.documents = documents.map(doc => ({
            ...doc,
            sizeKB: doc.contentSize ? (doc.contentSize / 1024) : 0
        }));
        this.filteredDocuments = [...this.documents];
        this.calculateMetrics();
        this.applyFilters();
    }

    calculateMetrics() {
        this.documentCount = this.documents.length;
        this.aiGeneratedCount = this.documents.filter(doc => doc.aiGenerated).length;
        this.contextQualityScore = this.calculateContextQuality();
        this.avgGenerationTime = this.calculateAvgGenerationTime();
    }

    calculateContextQuality() {
        if (this.documents.length === 0) return 0;
        const aiDocs = this.documents.filter(doc => doc.aiGenerated);
        if (aiDocs.length === 0) return 0;

        const qualitySum = aiDocs.reduce((sum, doc) => {
            let quality = 50;
            if (doc.templateName) quality += 20;
            if (doc.aiModel && doc.aiModel.includes('GPT')) quality += 20;
            if (doc.sizeKB > 5) quality += 10;
            return sum + Math.min(quality, 100);
        }, 0);

        return Math.round(qualitySum / aiDocs.length);
    }

    calculateAvgGenerationTime() {
        const aiDocs = this.documents.filter(doc => doc.aiGenerated);
        if (aiDocs.length === 0) return 0;

        const avgLength = aiDocs.reduce((sum, doc) => sum + (doc.sizeKB || 0), 0) / aiDocs.length;
        return (avgLength / 10 * 2.5).toFixed(1);
    }

    // ----------------- FILTERS -----------------
    get filterOptions() {
        return [
            { label: 'All Documents', value: '' },
            { label: 'AI Generated', value: 'ai' },
            { label: 'Manual Upload', value: 'manual' },
            { label: 'Word Documents', value: 'docx' },
            { label: 'PDF Documents', value: 'pdf' },
            { label: 'HTML Documents', value: 'html' }
        ];
    }

    handleSearch(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.applyFilters();
    }

    handleFilterChange(event) {
        this.selectedFilter = event.detail.value;
        this.applyFilters();
    }

    applyFilters() {
        let filtered = [...this.documents];

        if (this.searchTerm) {
            filtered = filtered.filter(doc =>
                doc.title.toLowerCase().includes(this.searchTerm) ||
                (doc.templateName && doc.templateName.toLowerCase().includes(this.searchTerm))
            );
        }

        if (this.selectedFilter) {
            switch (this.selectedFilter) {
                case 'ai':
                    filtered = filtered.filter(doc => doc.aiGenerated);
                    break;
                case 'manual':
                    filtered = filtered.filter(doc => !doc.aiGenerated);
                    break;
                case 'docx':
                    filtered = filtered.filter(doc => doc.fileType === 'WORD');
                    break;
                case 'pdf':
                    filtered = filtered.filter(doc => doc.fileType === 'PDF');
                    break;
                case 'html':
                    filtered = filtered.filter(doc => doc.fileType === 'HTML');
                    break;
            }
        }
        this.filteredDocuments = filtered;
    }

    // ----------------- SORTING -----------------
    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData();
    }

    sortData() {
        const parseData = [...this.filteredDocuments];
        const keyValue = (a) => a[this.sortedBy];
        const isReverse = this.sortDirection === 'asc' ? 1 : -1;

        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });

        this.filteredDocuments = parseData;
    }

    // ----------------- ANALYTICS -----------------
    async loadAnalytics() {
        try {
            this.analytics = await getGenerationAnalytics({
                folderId: this.recordId,
                dayRange: 30
            });
        } catch (error) {
            console.error('Analytics loading failed:', error);
        }
    }

    async handleExportAnalytics() {
        try {
            this.showToast('Info', 'Generating analytics report...', 'info');
            const result = await exportAnalyticsReport({
                folderId: this.recordId,
                dayRange: 30
            });

            if (result.success) {
                this.showToast('Success', 'Analytics report generated and saved', 'success');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.documentId,
                        actionName: 'view'
                    }
                });
            }
        } catch (error) {
            this.showToast('Error', 'Export failed: ' + error.body?.message, 'error');
        }
    }

    // ----------------- ROW ACTIONS -----------------
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view':
                this.viewDocument(row.id);
                break;
            case 'regenerate':
                this.regenerateDocument(row.id);
                break;
            case 'download':
                this.downloadDocument(row.id);
                break;
            case 'delete':
                this.deleteDocument(row.id);
                break;
        }
    }

    viewDocument(documentId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: { pageName: 'filePreview' },
            state: { recordIds: documentId }
        });
    }

    async regenerateDocument(documentId) {
        try {
            this.showToast('Info', 'Regenerating document...', 'info');
            await regenerateDocument({ documentId, newParameters: null });
            this.showToast('Success', 'Document regenerated successfully', 'success');
            return refreshApex(this.wiredDocumentsResult);
        } catch (error) {
            this.showToast('Error', 'Regeneration failed: ' + error.body?.message, 'error');
        }
    }

    downloadDocument(documentId) {
        const downloadUrl = `/sfc/servlet.shepherd/document/download/${documentId}`;
        window.open(downloadUrl, '_blank');
    }

    async deleteDocument(documentId) {
        if (confirm('Are you sure you want to delete this document?')) {
            try {
                await deleteGeneratedDocument({ documentId });
                this.showToast('Success', 'Document deleted successfully', 'success');
                return refreshApex(this.wiredDocumentsResult);
            } catch (error) {
                this.showToast('Error', 'Delete failed: ' + error.body?.message, 'error');
            }
        }
    }

    // ----------------- DOCUMENT CREATION -----------------
    handleNewDocument() {
        this.navigateToGenerator();
    }

    navigateToGenerator() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: { componentName: 'c__contextAwareDocumentGenerator' },
            state: { c__recordId: this.recordId }
        });
    }

    // ----------------- CONTEXT ANALYSIS -----------------
    async handleAnalyzeCollection() {
        this.showContextModal = true;
        this.isAnalyzing = true;

        try {
            this.contextAnalysis = await analyzeFolderContext({
                folderId: this.recordId,
                queryContext: 'collection_analysis'
            });
            this.processContextAnalysis();
        } catch (error) {
            this.showToast('Error', 'Context analysis failed: ' + error.body?.message, 'error');
            this.closeContextModal();
        } finally {
            this.isAnalyzing = false;
        }
    }

    processContextAnalysis() {
        if (!this.contextAnalysis) return;

        this.contextInsights = [];
        if (this.contextAnalysis.crossDocumentInsights) {
            for (const [key, value] of Object.entries(this.contextAnalysis.crossDocumentInsights)) {
                this.contextInsights.push({ id: key, key, value });
            }
        }

        this.entityFrequency = [];
        if (this.contextAnalysis.entityFrequency) {
            const totalEntities = Object.values(this.contextAnalysis.entityFrequency)
                .reduce((sum, count) => sum + count, 0);

            for (const [entity, count] of Object.entries(this.contextAnalysis.entityFrequency)) {
                if (count > 1) {
                    this.entityFrequency.push({
                        name: entity,
                        count,
                        percentage: Math.round((count / totalEntities) * 100)
                    });
                }
            }
            this.entityFrequency.sort((a, b) => b.count - a.count);
        }

        this.contextualSummary = this.contextAnalysis.contextualSummary || 'No contextual summary available.';
    }

    closeContextModal() {
        this.showContextModal = false;
        this.contextAnalysis = null;
    }

    // ----------------- UTILITY -----------------
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
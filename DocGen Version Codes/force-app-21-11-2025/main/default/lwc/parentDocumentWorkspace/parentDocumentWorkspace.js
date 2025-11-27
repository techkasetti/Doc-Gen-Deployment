import { LightningElement } from 'lwc';

export default class ParentDocumentWorkspace extends LightningElement {

    showTemplateManager = true;
    showGenerator = false;
    showViewer = false;
    showSignature = false;

    // Button highlight logic
    get templateManagerVariant() {
        return this.showTemplateManager ? "brand" : "neutral";
    }

    get generatorVariant() {
        return this.showGenerator ? "brand" : "neutral";
    }

    get viewerVariant() {
        return this.showViewer ? "brand" : "neutral";
    }

    get signatureVariant() {
        return this.showSignature ? "brand" : "neutral";
    }

    // Reset all
    hideAllSections() {
        this.showTemplateManager = false;
        this.showGenerator = false;
        this.showViewer = false;
        this.showSignature = false;
    }

    // Actions
    showTemplateManagerSection() {
        this.hideAllSections();
        this.showTemplateManager = true;
    }

    showGeneratorSection() {
        this.hideAllSections();
        this.showGenerator = true;
    }

    showViewerSection() {
        this.hideAllSections();
        this.showViewer = true;
    }

    showSignatureSection() {
        this.hideAllSections();
        this.showSignature = true;
    }
}

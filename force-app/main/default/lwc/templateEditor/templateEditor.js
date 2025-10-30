import { LightningElement, track } from 'lwc';
import createTemplate from '@salesforce/apex/TemplateService.createTemplate';
import listTemplates from '@salesforce/apex/TemplateService.listTemplates';

export default class TemplateEditor extends LightningElement {
  @track name = '';
  @track format = 'HTML';
  @track content = '';
  @track previewHtml = '';

  formatOptions = [
    { label: 'HTML', value: 'HTML' },
    { label: 'DOCX', value: 'DOCX' },
    { label: 'PDF', value: 'PDF' }
  ];

  handleNameChange(e) {
    this.name = e.target.value;
  }
  handleFormatChange(e) {
    this.format = e.detail.value;
  }
  handleContentChange(e) {
    this.content = e.target.value;
  }

  handleSave() {
    createTemplate({ name: this.name, content: this.content, format: this.format, isActive: true })
      .then(id => {
        // show success, refresh list
        this.dispatchEvent(new CustomEvent('saved', { detail: { id } }));
      })
      .catch(err => {
        console.error(err);
      });
  }

  handlePreview() {
    // lightweight preview for HTML
    if (this.format === 'HTML') {
      this.previewHtml = this.content;
      const container = this.template.querySelector('.preview-area');
      if (container) {
        container.innerHTML = this.previewHtml;
      }
    } else {
      // for non-HTML, basic placeholder
      this.previewHtml = 'Preview for format ' + this.format;
      const container = this.template.querySelector('.preview-area');
      if (container) container.innerText = this.previewHtml;
    }
  }
}
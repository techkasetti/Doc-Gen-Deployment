// Step 5.5: Production Monitoring LWC Component
// productionMonitoringDashboard.js

import { LightningElement, wire, track } from 'lwc';
import getSystemHealthStatus from '@salesforce/apex/ProductionMonitoringService.getSystemHealthStatus';
import getPerformanceMetrics from '@salesforce/apex/ProductionMonitoringService.getPerformanceMetrics';
import generateHealthReport from '@salesforce/apex/ProductionMonitoringService.generateHealthReport';
import acknowledgeAlert from '@salesforce/apex/ProductionMonitoringService.acknowledgeAlert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class ProductionMonitoringDashboard extends LightningElement {
    // Reactive tracked properties
    @track healthStatus = {};
    @track performanceMetrics = [];
    @track isLoading = true;
    @track selectedTimeRange = 7;
    @track healthReport = '';
    @track showHealthReport = false;

    // Time range dropdown options
    timeRangeOptions = [
        { label: '7 Days', value: 7 },
        { label: '14 Days', value: 14 },
        { label: '30 Days', value: 30 }
    ];

    // --- Wired Methods ---

    @wire(getSystemHealthStatus)
    wiredHealthStatus({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.healthStatus = data;
        } else if (error) {
            console.error('Error loading health status:', error);
            this.showToast('Error', 'Failed to load system health status', 'error');
        }
    }

    @wire(getPerformanceMetrics, { days: '$selectedTimeRange' })
    wiredPerformanceMetrics({ error, data }) {
        if (data) {
            this.performanceMetrics = data;
            this.updateCharts();
        } else if (error) {
            console.error('Error loading performance metrics:', error);
        }
    }

    // --- Lifecycle Hooks ---

    connectedCallback() {
        // Auto-refresh every 30 seconds
        this.refreshInterval = setInterval(() => {
            this.refreshData();
        }, 30000);
    }

    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }

    // --- Data Refresh ---

    refreshData() {
        return refreshApex(this.wiredHealthStatus);
    }

    // --- Event Handlers ---

    handleTimeRangeChange(event) {
        this.selectedTimeRange = parseInt(event.detail.value, 10);
    }

    async handleGenerateReport() {
        try {
            this.healthReport = await generateHealthReport();
            this.showHealthReport = true;
        } catch (error) {
            console.error('Error generating report:', error);
            this.showToast('Error', 'Failed to generate health report', 'error');
        }
    }

    handleCloseReport() {
        this.showHealthReport = false;
    }

    async handleAcknowledgeAlert(event) {
        const alertId = event.target.dataset.alertId;
        try {
            await acknowledgeAlert({ alertId });
            this.showToast('Success', 'Alert acknowledged', 'success');
            this.refreshData();
        } catch (error) {
            console.error('Error acknowledging alert:', error);
            this.showToast('Error', 'Failed to acknowledge alert', 'error');
        }
    }

    // --- Chart Updates ---

    updateCharts() {
        // Placeholder for Chart.js integration
        const ctx = this.template.querySelector('.performance-chart');
        if (ctx && this.performanceMetrics.length > 0) {
            const labels = this.performanceMetrics.map(m => m.date);
            const successRates = this.performanceMetrics.map(m => m.successRate);
            const responseTimes = this.performanceMetrics.map(m => m.avgResponseTime);

            // TODO: Implement Chart.js with labels, successRates, and responseTimes
        }
    }

    // --- Getters ---

    get statusClass() {
        const status = this.healthStatus.overallStatus;
        switch (status) {
            case 'HEALTHY':  return 'status-healthy';
            case 'WARNING':  return 'status-warning';
            case 'CRITICAL': return 'status-critical';
            default:         return 'status-unknown';
        }
    }

    get uptimePercentage() {
        // Calculate uptime percentage (assuming 24/7 operation)
        const totalHours = 24 * 7; // 7 days
        return this.healthStatus.uptime
            ? Math.min(100, (this.healthStatus.uptime / totalHours) * 100).toFixed(2)
            : 0;
    }

    // --- Utility ---

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
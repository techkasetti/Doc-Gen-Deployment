import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getCurrentHealthMetrics from '@salesforce/apex/SystemHealthMonitor.getCurrentHealthMetrics';
import acknowledgeAlert from '@salesforce/apex/SystemHealthMonitor.acknowledgeAlert';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';

export default class SystemHealthDashboard extends LightningElement {
    @track healthMetrics = {};
    @track isLoading = true;
    @track selectedTrendMetric = 'Generation Time';
    @track chartInstance = null;
    @track refreshInterval;
    wiredHealthResult;

    connectedCallback() {
        this.loadChartLibrary();
        this.startAutoRefresh();
    }

    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
        if (this.chartInstance) {
            this.chartInstance.destroy();
        }
    }

    @wire(getCurrentHealthMetrics) 
    wiredHealth(result) {
        this.wiredHealthResult = result;
        if (result.data) {
            this.healthMetrics = result.data;
            this.processHealthData();
            this.isLoading = false;
            this.updateTrendChart();
        } else if (result.error) {
            this.showToast('Error', 'Failed to load health metrics', 'error');
            this.isLoading = false;
        }
    }

    processHealthData() {
        if (this.healthMetrics.alerts) {
            this.activeAlerts = this.healthMetrics.alerts.activeAlerts || [];
            this.alertCount = this.healthMetrics.alerts.alertCount || 0;
            this.processAlertTimestamps();
        }
    }

    processAlertTimestamps() {
        this.activeAlerts = this.activeAlerts.map(alert => ({
            ...alert,
            formattedTimestamp: this.formatTimestamp(alert.timestamp),
            id: this.generateAlertId(alert)
        }));
    }

    formatTimestamp(timestamp) {
        return new Date(timestamp).toLocaleString();
    }

    generateAlertId(alert) {
        return `${alert.category}_${alert.timestamp}`;
    }

    async loadChartLibrary() {
        try {
            await loadScript(this, ChartJS);
        } catch (error) {
            console.error('Error loading Chart.js', error);
        }
    }

    startAutoRefresh() {
        this.refreshInterval = setInterval(() => {
            refreshApex(this.wiredHealthResult);
        }, 30000);
    }

    updateTrendChart() {
        if (!this.chartInstance || !this.healthMetrics.performanceTrends) return;

        const filteredData = this.healthMetrics.performanceTrends.filter(
            point => point.metric === this.selectedTrendMetric
        );
        const labels = filteredData.map(point => new Date(point.timestamp).toLocaleTimeString());
        const data = filteredData.map(point => point.value);

        this.chartInstance.data.labels = labels;
        this.chartInstance.data.datasets[0].data = data;
        this.chartInstance.update();
    }

    renderedCallback() {
        if (this.chartInstance) return;
        const canvas = this.template.querySelector('canvas[lwc\\:ref="trendChart"]');
        if (canvas && window.Chart) {
            this.initializeChart(canvas);
        }
    }

    initializeChart(canvas) {
        const ctx = canvas.getContext('2d');
        this.chartInstance = new window.Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: this.selectedTrendMetric,
                    data: [],
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    tension: 0.1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: this.getYAxisLabel()
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Time'
                        }
                    }
                },
                plugins: {
                    legend: { display: true },
                    title: {
                        display: true,
                        text: `${this.selectedTrendMetric} Trend`
                    }
                }
            }
        });
        this.updateTrendChart();
    }

    getYAxisLabel() {
        switch (this.selectedTrendMetric) {
            case 'Generation Time': return 'Seconds';
            case 'System Uptime': return 'Percentage';
            case 'Cache Hit Ratio': return 'Percentage';
            default: return 'Value';
        }
    }

    get trendMetricOptions() {
        return [
            { label: 'Generation Time', value: 'Generation Time' },
            { label: 'System Uptime', value: 'System Uptime' },
            { label: 'Cache Hit Ratio', value: 'Cache Hit Ratio' }
        ];
    }

    // --- SLA Status ---
    get slaStatusClass() {
        const sla = this.healthMetrics.documentGenerationSLA || 0;
        return sla >= 95 ? 'slds-text-color_success'
             : sla >= 80 ? 'slds-text-color_warning'
             : 'slds-text-color_error';
    }
    get slaVariant() {
        const sla = this.healthMetrics.documentGenerationSLA || 0;
        return sla >= 95 ? 'base-autocomplete'
             : sla >= 80 ? 'warning'
             : 'expired';
    }

    // --- Uptime ---
    get uptimeStatusClass() {
        const uptime = this.healthMetrics.systemUptime || 0;
        return uptime >= 99.5 ? 'slds-text-color_success'
             : uptime >= 99 ? 'slds-text-color_warning'
             : 'slds-text-color_error';
    }
    get uptimeVariant() {
        const uptime = this.healthMetrics.systemUptime || 0;
        return uptime >= 99.5 ? 'base-autocomplete'
             : uptime >= 99 ? 'warning'
             : 'expired';
    }

    // --- Compliance ---
    get complianceStatusClass() {
        const score = this.healthMetrics.complianceScore || 0;
        return score >= 95 ? 'slds-text-color_success'
             : score >= 90 ? 'slds-text-color_warning'
             : 'slds-text-color_error';
    }
    get complianceVariant() {
        const score = this.healthMetrics.complianceScore || 0;
        return score >= 95 ? 'base-autocomplete'
             : score >= 90 ? 'warning'
             : 'expired';
    }

    // --- Error Rate ---
    get errorRateClass() {
        const rate = this.healthMetrics.errorRate || 0;
        return rate <= 1 ? 'slds-text-color_success'
             : rate <= 5 ? 'slds-text-color_warning'
             : 'slds-text-color_error';
    }

    // --- Cache Hit ---
    get cacheHitClass() {
        const ratio = this.healthMetrics.cacheHitRatio || 0;
        return ratio >= 85 ? 'slds-text-color_success'
             : ratio >= 70 ? 'slds-text-color_warning'
             : 'slds-text-color_error';
    }

    get queueDepthClass() {
        const depth = this.healthMetrics.queueDepth || 0;
        return depth === 0 ? 'slds-text-color_success'
             : depth <= 5 ? 'slds-text-color_warning'
             : 'slds-text-color_error';
    }

    get hasAlerts() {
        return this.activeAlerts && this.activeAlerts.length > 0;
    }

    get alertsBadgeVariant() {
        const highSeverityCount = this.healthMetrics.alerts?.highSeverityCount || 0;
        return highSeverityCount > 0 ? 'error'
             : this.alertCount > 0 ? 'warning'
             : 'success';
    }

    // --- DocGen ---
    get docGenStatusIcon() {
        const sla = this.healthMetrics.documentGenerationSLA || 0;
        return sla >= 95 ? 'utility:success'
             : sla >= 80 ? 'utility:warning'
             : 'utility:error';
    }
    get docGenStatusVariant() {
        const sla = this.healthMetrics.documentGenerationSLA || 0;
        return sla >= 95 ? 'success'
             : sla >= 80 ? 'warning'
             : 'error';
    }
    get docGenStatusClass() {
        const sla = this.healthMetrics.documentGenerationSLA || 0;
        return sla >= 95 ? 'slds-text-body_small slds-text-color_success'
             : sla >= 80 ? 'slds-text-body_small slds-text-color_warning'
             : 'slds-text-body_small slds-text-color_error';
    }
    get docGenStatusText() {
        const sla = this.healthMetrics.documentGenerationSLA || 0;
        return sla >= 95 ? 'Optimal'
             : sla >= 80 ? 'Degraded'
             : 'Critical';
    }

    // --- Compliance Status ---
    get complianceStatusIcon() {
        const score = this.healthMetrics.complianceScore || 0;
        return score >= 95 ? 'utility:success'
             : score >= 90 ? 'utility:warning'
             : 'utility:error';
    }
    get complianceStatusIconVariant() {
        const score = this.healthMetrics.complianceScore || 0;
        return score >= 95 ? 'success'
             : score >= 90 ? 'warning'
             : 'error';
    }
    get complianceStatusTextClass() {
        const score = this.healthMetrics.complianceScore || 0;
        return score >= 95 ? 'slds-text-body_small slds-text-color_success'
             : score >= 90 ? 'slds-text-body_small slds-text-color_warning'
             : 'slds-text-body_small slds-text-color_error';
    }
    get complianceStatusText() {
        const score = this.healthMetrics.complianceScore || 0;
        return score >= 95 ? 'Compliant'
             : score >= 90 ? 'Minor Issues'
             : 'Non-Compliant';
    }

    // --- Cache Status ---
    get cacheStatusIcon() {
        const ratio = this.healthMetrics.cacheHitRatio || 0;
        return ratio >= 85 ? 'utility:success'
             : ratio >= 70 ? 'utility:warning'
             : 'utility:error';
    }
    get cacheStatusVariant() {
        const ratio = this.healthMetrics.cacheHitRatio || 0;
        return ratio >= 85 ? 'success'
             : ratio >= 70 ? 'warning'
             : 'error';
    }
    get cacheStatusClass() {
        const ratio = this.healthMetrics.cacheHitRatio || 0;
        return ratio >= 85 ? 'slds-text-body_small slds-text-color_success'
             : ratio >= 70 ? 'slds-text-body_small slds-text-color_warning'
             : 'slds-text-body_small slds-text-color_error';
    }
    get cacheStatusText() {
        const ratio = this.healthMetrics.cacheHitRatio || 0;
        return ratio >= 85 ? 'Optimal'
             : ratio >= 70 ? 'Suboptimal'
             : 'Poor';
    }

    // --- Alerts ---
    getAlertClass(alert) {
        const severity = alert.severity;
        const baseClass = 'slds-box slds-box_x-small slds-m-bottom_x-small';
        switch (severity) {
            case 'CRITICAL': return baseClass + ' slds-theme_error';
            case 'HIGH': return baseClass + ' slds-theme_warning';
            case 'MEDIUM': return baseClass + ' slds-theme_info';
            default: return baseClass + ' slds-theme_default';
        }
    }
    getAlertIcon(alert) {
        switch (alert.severity) {
            case 'CRITICAL': return 'utility:error';
            case 'HIGH': return 'utility:warning';
            case 'MEDIUM': return 'utility:info';
            default: return 'utility:notification';
        }
    }
    getAlertIconVariant(alert) {
        switch (alert.severity) {
            case 'CRITICAL': return 'error';
            case 'HIGH': return 'warning';
            case 'MEDIUM': return 'info';
            default: return 'default';
        }
    }

    // --- Actions ---
    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredHealthResult);
    }

    async handleExportReport() {
        try {
            this.showToast('Info', 'Generating health report...', 'info');

            const reportData = {
                timestamp: new Date().toISOString(),
                metrics: this.healthMetrics,
                summary: this.generateHealthSummary()
            };

            const blob = new Blob([JSON.stringify(reportData, null, 2)], { type: 'application/json' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `system-health-report-${new Date().toISOString().split('T')[0]}.json`;

            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);

            this.showToast('Success', 'Health report exported successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Export failed: ' + error.message, 'error');
        }
    }

    generateHealthSummary() {
        const sla = this.healthMetrics.documentGenerationSLA || 0;
        const uptime = this.healthMetrics.systemUptime || 0;
        const compliance = this.healthMetrics.complianceScore || 0;
        const errorRate = this.healthMetrics.errorRate || 0;

        let status = 'HEALTHY';
        if (sla < 80 || uptime < 99 || compliance < 90 || errorRate > 5) {
            status = 'DEGRADED';
        }
        if (sla < 60 || uptime < 95 || compliance < 80 || errorRate > 10) {
            status = 'CRITICAL';
        }

        return {
            overallStatus: status,
            keyMetrics: {
                documentGenerationSLA: sla,
                systemUptime: uptime,
                complianceScore: compliance,
                errorRate: errorRate
            },
            recommendations: this.generateRecommendations()
        };
    }

    generateRecommendations() {
        const recommendations = [];
        const sla = this.healthMetrics.documentGenerationSLA || 0;
        const uptime = this.healthMetrics.systemUptime || 0;
        const compliance = this.healthMetrics.complianceScore || 0;
        const errorRate = this.healthMetrics.errorRate || 0;
        const cacheHit = this.healthMetrics.cacheHitRatio || 0;

        if (sla < 95) {
            recommendations.push('Optimize document generation performance - current SLA below target');
        }
        if (uptime < 99.5) {
            recommendations.push('Investigate system stability issues - uptime below target');
        }
        if (compliance < 95) {
            recommendations.push('Review compliance processes - score below target');
        }
        if (errorRate > 1) {
            recommendations.push('Investigate and reduce system error rate');
        }
        if (cacheHit < 85) {
            recommendations.push('Optimize caching strategy to improve performance');
        }
        if (recommendations.length === 0) {
            recommendations.push('All systems operating within normal parameters');
        }

        return recommendations;
    }

    handleTrendMetricChange(event) {
        this.selectedTrendMetric = event.detail.value;
        if (this.chartInstance) {
            this.chartInstance.data.datasets[0].label = this.selectedTrendMetric;
            this.chartInstance.options.plugins.title.text = `${this.selectedTrendMetric} Trend`;
            this.chartInstance.options.scales.y.title.text = this.getYAxisLabel();
            this.updateTrendChart();
        }
    }

    async handleAcknowledgeAlert(event) {
        const alertId = event.target.dataset.alertId;
        try {
            await acknowledgeAlert({ alertId: alertId });
            this.showToast('Success', 'Alert acknowledged successfully', 'success');
            this.activeAlerts = this.activeAlerts.filter(alert => alert.id !== alertId);
            this.alertCount = this.activeAlerts.length;
        } catch (error) {
            this.showToast('Error', 'Failed to acknowledge alert: ' + error.body?.message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}

import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAnalyticsData from '@salesforce/apex/AnalyticsController.getAnalyticsData';
import getRecentActivity from '@salesforce/apex/AnalyticsController.getRecentActivity';
import getAdvancedAnalytics from '@salesforce/apex/AnalyticsController.getAdvancedAnalytics';
import exportAnalyticsData from '@salesforce/apex/AnalyticsController.exportAnalyticsData';

export default class SignatureAnalytics extends LightningElement {
    @track analyticsData = {};
    @track recentActivities = [];
    @track isLoading = true;
    @track error;
    @track chartJsInitialized = false;

    wiredAnalyticsResult;
    wiredActivityResult;

    // ------------------- Wired Methods -------------------
    @wire(getAnalyticsData)
    wiredAnalytics(result) {
        this.wiredAnalyticsResult = result;
        if (result.data) {
            this.analyticsData = result.data;
            this.error = undefined;
            this.isLoading = false;
            this.initializeCharts();
        } else if (result.error) {
            this.error = result.error.body.message;
            this.isLoading = false;
        }
    }

    @wire(getRecentActivity, { limitCount: 10 })
    wiredRecentActivity(result) {
        this.wiredActivityResult = result;
        if (result.data) {
            this.recentActivities = result.data;
        } else if (result.error) {
            console.error('Error loading recent activity:', result.error);
        }
    }

    // ------------------- Lifecycle Hooks -------------------
    connectedCallback() {
        this.loadChartJs();
    }

    renderedCallback() {
        if (this.chartJsInitialized && this.analyticsData.statusDistribution) {
            this.renderCharts();
        }
    }

    // ------------------- Computed Properties -------------------
    get formattedCompletionRate() {
        return this.analyticsData.completionRate ?
            Math.round(this.analyticsData.completionRate * 100) / 100 : 0;
    }

    get formattedAvgTime() {
        return this.analyticsData.avgCompletionTime ?
            Math.round(this.analyticsData.avgCompletionTime * 100) / 100 : 0;
    }

    get formattedUptime() {
        return this.analyticsData.systemUptime ?
            Math.round(this.analyticsData.systemUptime * 100) / 100 : 0;
    }

    get formattedPerformanceScore() {
        return this.analyticsData.performanceScore ?
            Math.round(this.analyticsData.performanceScore) : 0;
    }

    get systemStatusClass() {
        const status = this.analyticsData.systemStatus;
        if (status === 'Healthy') return 'health-status-healthy';
        if (status === 'Warning') return 'health-status-warning';
        if (status === 'Critical') return 'health-status-critical';
        return 'health-status-unknown';
    }

    get lastUpdated() {
        return new Date().toLocaleString();
    }

    // ------------------- Chart Initialization -------------------
    async loadChartJs() {
        try {
            await loadScript(this, '/resource/ChartJs');
            this.chartJsInitialized = true;
            this.initializeCharts();
        } catch (error) {
            console.error('Error loading Chart.js:', error);
            this.showToast('Error', 'Failed to load chart library', 'error');
        }
    }

    initializeCharts() {
        if (this.chartJsInitialized && this.analyticsData.statusDistribution) {
            setTimeout(() => {
                this.renderCharts();
            }, 100);
        }
    }

    renderCharts() {
        try {
            this.renderStatusChart();
            this.renderTrendChart();
        } catch (error) {
            console.error('Error rendering charts:', error);
        }
    }

    renderStatusChart() {
        const canvas = this.template.querySelector('[lwc\\:ref="statusChart"]');
        if (!canvas || !this.analyticsData.statusDistribution) return;

        const ctx = canvas.getContext('2d');
        const labels = this.analyticsData.statusDistribution.map(item => item.status);
        const data = this.analyticsData.statusDistribution.map(item => item.count);

        new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: labels,
                datasets: [{
                    data: data,
                    backgroundColor: [
                        '#4CAF50', // Completed
                        '#FF9800', // Pending
                        '#F44336', // Rejected
                        '#9E9E9E'  // Expired
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' }
                }
            }
        });
    }

    renderTrendChart() {
        const canvas = this.template.querySelector('[lwc\\:ref="trendChart"]');
        if (!canvas || !this.analyticsData.completionTrends) return;

        const ctx = canvas.getContext('2d');
        const labels = this.analyticsData.completionTrends.map(item =>
            new Date(item.date).toLocaleDateString()
        );
        const totalData = this.analyticsData.completionTrends.map(item => item.total);
        const completedData = this.analyticsData.completionTrends.map(item => item.completed);

        new Chart(ctx, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Total Requests',
                        data: totalData,
                        borderColor: '#2196F3',
                        backgroundColor: 'rgba(33, 150, 243, 0.1)',
                        tension: 0.4
                    },
                    {
                        label: 'Completed',
                        data: completedData,
                        borderColor: '#4CAF50',
                        backgroundColor: 'rgba(76, 175, 80, 0.1)',
                        tension: 0.4
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' }
                },
                scales: { y: { beginAtZero: true } }
            }
        });
    }

    // ------------------- Event Handlers -------------------
    async refreshAnalytics() {
        this.isLoading = true;
        try {
            await refreshApex(this.wiredAnalyticsResult);
            await refreshApex(this.wiredActivityResult);
            this.showToast('Success', 'Analytics data refreshed', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to refresh data', 'error');
        }
    }

    async exportReport() {
        try {
            await exportAnalyticsData({ format: 'PDF' });
            this.showToast('Success', 'Report exported successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to export report', 'error');
        }
    }

    openSettings() {
        this.showToast('Info', 'Settings panel coming soon', 'info');
    }

    // ------------------- Utility Methods -------------------
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    // ------------------- Advanced Analytics -------------------
    async loadAdvancedAnalytics() {
        try {
            const result = await getAdvancedAnalytics({
                timeframe: 'last_30_days',
                includeSystemHealth: true
            });

            if (result.systemHealth) {
                this.systemHealthData = result.systemHealth;
            }

            this.showToast('Success', 'Advanced analytics loaded', 'success');
        } catch (error) {
            console.error('Error loading advanced analytics:', error);
            this.showToast('Error', 'Failed to load advanced analytics', 'error');
        }
    }

    // ------------------- Real-Time Updates -------------------
    handleRealTimeUpdate(event) {
        const updatedData = event.detail;
        if (updatedData.type === 'signature_completed') {
            this.refreshAnalytics();
        }
    }

    // ------------------- Performance Monitoring -------------------
    startPerformanceMonitoring() {
        setInterval(() => {
            this.checkPerformanceMetrics();
        }, 30000); // Every 30 seconds
    }

    async checkPerformanceMetrics() {
        try {
            const performanceData = await getAdvancedAnalytics({
                timeframe: 'last_hour',
                includeSystemHealth: true
            });

            if (performanceData.systemHealth) {
                this.updateSystemHealthIndicators(performanceData.systemHealth);
            }
        } catch (error) {
            console.error('Performance monitoring error:', error);
        }
    }

    updateSystemHealthIndicators(healthData) {
        if (healthData.cpuUtilization > 90) {
            this.showToast('Warning', 'High CPU utilization detected', 'warning');
        }
        if (healthData.memoryUsage > 85) {
            this.showToast('Warning', 'High memory usage detected', 'warning');
        }
        if (healthData.dbResponseTime > 1000) {
            this.showToast('Warning', 'Database response time is slow', 'warning');
        }
    }
}
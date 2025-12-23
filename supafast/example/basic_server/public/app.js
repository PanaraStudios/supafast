// Supafast Static Files Demo JavaScript

console.log('🚀 Supafast static file serving working perfectly!');

// Demo functionality
document.addEventListener('DOMContentLoaded', function() {
    // Add loading animation to feature cards
    const featureCards = document.querySelectorAll('.feature-card');
    
    // Animate cards on load
    featureCards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        
        setTimeout(() => {
            card.style.transition = 'all 0.6s ease';
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, index * 200);
    });
    
    // Add click handlers for demo links
    const demoLinks = document.querySelectorAll('.demo-section a');
    demoLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            if (this.getAttribute('href').endsWith('.js') || 
                this.getAttribute('href').endsWith('.css') ||
                this.getAttribute('href').endsWith('.json')) {
                e.preventDefault();
                
                // Show a nice notification
                showNotification(`Opening ${this.getAttribute('href')} - Static file serving demo!`);
                
                // Open in new tab after a delay
                setTimeout(() => {
                    window.open(this.getAttribute('href'), '_blank');
                }, 1000);
            }
        });
    });
    
    // Add performance timing information
    if (window.performance && window.performance.timing) {
        const loadTime = window.performance.timing.loadEventEnd - window.performance.timing.navigationStart;
        console.log(`Page loaded in ${loadTime}ms`);
        
        // Add timing info to page
        const timingDiv = document.createElement('div');
        timingDiv.style.cssText = `
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: rgba(102, 126, 234, 0.9);
            color: white;
            padding: 10px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-family: monospace;
            z-index: 1000;
        `;
        timingDiv.textContent = `Load time: ${loadTime}ms`;
        document.body.appendChild(timingDiv);
    }
});

// Helper function to show notifications
function showNotification(message) {
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #4CAF50;
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        z-index: 1000;
        font-weight: 500;
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        opacity: 0;
        transform: translateY(-20px);
        transition: all 0.3s ease;
    `;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.opacity = '1';
        notification.style.transform = 'translateY(0)';
    }, 100);
    
    // Remove after delay
    setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transform = 'translateY(-20px)';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// Test API endpoint from JavaScript
async function testApiEndpoint() {
    try {
        const response = await fetch('/api/v1/test');
        const data = await response.json();
        console.log('API test successful:', data);
        showNotification('API endpoint test successful!');
    } catch (error) {
        console.error('API test failed:', error);
        showNotification('API endpoint test failed!');
    }
}

// Test JSON body parsing
async function testBodyParsing() {
    try {
        const response = await fetch('/echo', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: 'Hello from JavaScript!',
                timestamp: new Date().toISOString()
            })
        });
        const data = await response.json();
        console.log('Body parsing test successful:', data);
        showNotification('Body parsing test successful!');
    } catch (error) {
        console.error('Body parsing test failed:', error);
        showNotification('Body parsing test failed!');
    }
}

// Add test buttons to the page
document.addEventListener('DOMContentLoaded', function() {
    const demoSection = document.querySelector('.demo-section ul');
    
    // Add API test button
    const apiTestLi = document.createElement('li');
    const apiTestButton = document.createElement('button');
    apiTestButton.textContent = 'Test API Endpoint';
    apiTestButton.style.cssText = `
        padding: 0.75rem 1.5rem;
        background: #667eea;
        color: white;
        border: none;
        border-radius: 8px;
        cursor: pointer;
        font-weight: 500;
        transition: all 0.3s ease;
    `;
    apiTestButton.addEventListener('click', testApiEndpoint);
    apiTestButton.addEventListener('mouseover', () => {
        apiTestButton.style.background = '#5a67d8';
        apiTestButton.style.transform = 'translateX(5px)';
    });
    apiTestButton.addEventListener('mouseout', () => {
        apiTestButton.style.background = '#667eea';
        apiTestButton.style.transform = 'translateX(0)';
    });
    apiTestLi.appendChild(apiTestButton);
    demoSection.appendChild(apiTestLi);
    
    // Add body parsing test button
    const bodyTestLi = document.createElement('li');
    const bodyTestButton = document.createElement('button');
    bodyTestButton.textContent = 'Test Body Parsing';
    bodyTestButton.style.cssText = apiTestButton.style.cssText;
    bodyTestButton.addEventListener('click', testBodyParsing);
    bodyTestButton.addEventListener('mouseover', () => {
        bodyTestButton.style.background = '#5a67d8';
        bodyTestButton.style.transform = 'translateX(5px)';
    });
    bodyTestButton.addEventListener('mouseout', () => {
        bodyTestButton.style.background = '#667eea';
        bodyTestButton.style.transform = 'translateX(0)';
    });
    bodyTestLi.appendChild(bodyTestButton);
    demoSection.appendChild(bodyTestLi);
});
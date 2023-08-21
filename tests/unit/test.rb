# Verifica si PHP está instalado
control 'php-installed' do
    impact 0.7
    title 'PHP should be installed'
    desc 'Verify that PHP is installed'
    
    describe package('php') do
      it { should be_installed }
    end
  end

# Verifica si apache2 está instalado
control 'apache2-installed' do
    impact 0.7
    title 'Apache2 should be installed'
    desc 'Verify that Apache2 is installed'
    
    describe package('apache2') do
      it { should be_installed }
    end
  end
  
# Verifica si MySQL está instalado
control 'mysql-installed' do
    impact 0.7
    title 'MySQL should be installed'
    desc 'Verify that MySQL is installed'
    
    describe package('mysql-server') do
      it { should be_installed }
    end
  end

# Verifica si php-mysql está instalado
control 'php-mysql-installed' do
    impact 0.7
    title 'php-mysql package should be installed'
    desc 'Verify that the php-mysql package is installed'
    
    describe package('php-mysql') do
      it { should be_installed }
    end
  end

# Verifica si el servicio de apache se está ejecutando
control 'apache2-service' do
    impact 0.5
    title 'Apache2 service should be running'
    desc 'Verify that the Apache2 service is running'
    
    describe service('apache2') do
      it { should be_running }
    end
  end
  
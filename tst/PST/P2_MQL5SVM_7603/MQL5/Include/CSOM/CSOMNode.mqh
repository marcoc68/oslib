//|------------------------------------------------------------------+
//|                                                     CSOMNode.mqh |
//|                                    Copyright (c) 2018, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                           https://www.mql5.com/ru/articles/5472/ |
//|                           https://www.mql5.com/ru/articles/5473/ |
//|------------------------------------------------------------------+

class CSOMNode
{
  protected:
    int x, y; // coordinates in hosting map
    
    double m_weights[];
    int m_dimension;
    double m_distance;
    
    int m_hitCount;
    double m_sum[];
    double m_sumP2[];
    double m_mse;
    long m_updateCount;
    int m_cluster;
    bool m_selected;
    double m_output;
    
    static uint defaultDimension;
    static int dimensionMax;
    static ulong dimensionBitMask;
    
  public:
    CSOMNode(const uint dim = 0);
    ~CSOMNode();
    void InitNode(const int x0, const int y0);
    int GetX() const { return x; }
    int GetY() const { return y; }
    double GetWeight(const int index) const;
    void GetCodeVector(double &vector[]) const;
    double GetDistance() const;
    double CalculateDistance(const double &vector[]) const;
    double CalculateDistance(const CSOMNode *other) const;
    double CalculateOutput(const double &vector[]);
    static void SetFeatureMask(const int dim = 0, const ulong bitmask = 0);
    void AdjustWeights(const double &vector[], const double learning_rate, const double influence);
    void SetDimension(const int dimension);
    void SetDistance(const double d);
    void Save(const int handle) const;
    void Load(const int handle);
    
    void RegisterPatternHit(const double &vector[]);
    int GetHitsCount() const;
    void SetHitsCount(const int n) { m_hitCount = n; }
    double GetHitsMean(const int plane) const;
    double GetHitsDeviation(const int plane) const;
    double GetMSE() const;
    long GetUpdateCount() const;
    void SetCluster(int index);
    int GetCluster() const;
    void Select() { m_selected = !m_selected; }
    bool IsSelected() const { return m_selected; }
    double GetOutput() const { return m_output; }
    
    static void FactoryInit(const uint dim);
};

static uint CSOMNode::defaultDimension = 0;
static int CSOMNode::dimensionMax = 0;
static ulong CSOMNode::dimensionBitMask = 0;

static void CSOMNode::FactoryInit(const uint dim)
{
  defaultDimension = dim;
}

void CSOMNode::CSOMNode(const uint dim = 0)
{
  x = y = 0;
  m_distance = 0.0;
  m_hitCount = 0;
  m_updateCount = 0;
  m_mse = 0;
  m_cluster = 0;
  m_selected = false;
  m_output = 0;
  SetDimension(dim ? dim : defaultDimension);
}

void CSOMNode::InitNode(const int x0, const int y0)
{
  x = x0;
  y = y0;
  ArrayResize(m_weights, m_dimension);
  ArrayResize(m_sum, m_dimension);
  ArrayResize(m_sumP2, m_dimension);
  ArrayInitialize(m_sum, 0);
  ArrayInitialize(m_sumP2, 0);

  for(int i = 0; i < m_dimension; i++)
  {
    m_weights[i] = 2.0 * rand() / 32768 - 1.0;
  }
}

void CSOMNode::~CSOMNode()
{
  ArrayResize(m_weights, 0);
  ArrayResize(m_sum, 0);
  ArrayResize(m_sumP2, 0);
}

double CSOMNode::GetWeight(const int weight_index) const
{
  if(weight_index >= 0 && weight_index < m_dimension)
    return m_weights[weight_index];
  else
    return 0;
}

void CSOMNode::GetCodeVector(double &vector[]) const
{
  ArrayCopy(vector, m_weights);
}

static void CSOMNode::SetFeatureMask(const int dim = 0, const ulong bitmask = 0)
{
  dimensionMax = dim;
  dimensionBitMask = bitmask;
}

double CSOMNode::CalculateDistance(const double &vector[]) const
{
  double distSqr = 0;
  if(dimensionMax <= 0 || dimensionMax > m_dimension) dimensionMax = m_dimension;
  for(int i = 0; i < dimensionMax; i++)
  {
    if(dimensionBitMask == 0 || ((dimensionBitMask & (1 << i)) != 0))
    {
      distSqr += (vector[i] - m_weights[i]) * (vector[i] - m_weights[i]);
    }
  }
  return distSqr;
}

double CSOMNode::CalculateDistance(const CSOMNode *other) const
{
  double vector[];
  other.GetCodeVector(vector);
  return CalculateDistance(vector);
}

double CSOMNode::CalculateOutput(const double &vector[])
{
  m_output = CalculateDistance(vector);
  return m_output;
}

void CSOMNode::AdjustWeights(const double &vector[], const double learning_rate, const double influence)
{
  m_updateCount++;
  for(int i = 0; i < m_dimension; i++)
  {
    m_weights[i] += learning_rate * influence * (vector[i] - m_weights[i]);
  }
}

void CSOMNode::SetDimension(const int dimension)
{
  m_dimension = dimension;
  ArrayResize(m_weights, m_dimension);
}

void CSOMNode::SetDistance(const double d)
{
  m_distance = d;
}

double CSOMNode::GetDistance() const
{
  return m_distance;
}

void CSOMNode::Save(const int handle) const
{
  FileWriteInteger(handle, x);
  FileWriteInteger(handle, y);
  FileWriteArray(handle, m_weights);
  
  FileWriteDouble(handle, m_distance);
  FileWriteInteger(handle, m_hitCount);
  FileWriteArray(handle, m_sum);
  FileWriteArray(handle, m_sumP2);
  FileWriteDouble(handle, m_mse);
  FileWriteInteger(handle, m_cluster);
}

void CSOMNode::Load(const int handle)
{
  x = FileReadInteger(handle);
  y = FileReadInteger(handle);
  FileReadArray(handle, m_weights, 0, m_dimension);
  
  m_distance = FileReadDouble(handle);
  m_hitCount = FileReadInteger(handle);
  FileReadArray(handle, m_sum, 0, m_dimension);
  FileReadArray(handle, m_sumP2, 0, m_dimension);
  m_mse = FileReadDouble(handle);
  m_cluster = FileReadInteger(handle);
}

void CSOMNode::RegisterPatternHit(const double &vector[])
{
  m_hitCount++;
  double e = 0;
  for(int i = 0; i < m_dimension; i++) // dimensionMax
  {
    m_sum[i] += vector[i];
    m_sumP2[i] += vector[i] * vector[i];
    e += (m_weights[i] - vector[i]) * (m_weights[i] - vector[i]);
  }
  m_mse += e / m_dimension;
}

int CSOMNode::GetHitsCount() const
{
  return m_hitCount;
}

double CSOMNode::GetHitsMean(const int plane) const
{
  if(m_hitCount == 0) return 0;
  return m_sum[plane] / m_hitCount;
}

double CSOMNode::GetHitsDeviation(const int plane) const
{
  if(m_hitCount == 0) return 0;
  double z = m_sumP2[plane] / m_hitCount - m_sum[plane] / m_hitCount * m_sum[plane] / m_hitCount;
  if(z < 0) return 0;
  return MathSqrt(z);
}

double CSOMNode::GetMSE() const
{
  if(m_hitCount == 0) return 0;
  return m_mse / m_hitCount;
}

long CSOMNode::GetUpdateCount() const
{
  return m_updateCount;
}

void CSOMNode::SetCluster(int index)
{
  m_cluster = index;
}

int CSOMNode::GetCluster() const
{
  return m_cluster;
}

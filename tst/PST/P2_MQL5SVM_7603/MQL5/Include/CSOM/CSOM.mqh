//|------------------------------------------------------------------+
//|                                                         CSOM.mqh |
//|                               Copyright (c) 2018-2019, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                           https://www.mql5.com/ru/articles/5472/ |
//|                           https://www.mql5.com/ru/articles/5473/ |
//|------------------------------------------------------------------+

#include <CSOM/CSOMNode.mqh>

#include <Math/Alglib/dataanalysis.mqh>


#define EXTRA_DIMENSIONS 5
#define DIM_HITCOUNT (m_dimension + 0)
#define DIM_UMATRIX  (m_dimension + 1)
#define DIM_NODEMSE  (m_dimension + 2) // quantization errors per node: average variance (square of standard deviation)
#define DIM_CLUSTERS (m_dimension + 3)
#define DIM_OUTPUT   (m_dimension + 4)

#define NBH_SQUARE_SIZE    4
#define NBH_HEXAGONAL_SIZE 6

#define KMEANS_RETRY_NUMBER 10

#define FILE_EXT_SOM ".som"
#define FILE_EXT_CSV ".csv"

const string extras[EXTRA_DIMENSIONS] = {"HitCount", "U-matrix", "Error", "Clusters", "Output"};

class CSOM
{
  protected:
    // data structure
    int m_xcells;      // number of map cells (nodes) by x
    int m_ycells;      // and by y
    CSOMNode m_node[]; // array of Kohonen map nodes
    int m_nSet;        // number of data records
    double m_set[];    // array of data records
    double m_max[];    // max values in every dimension
    double m_min[];    // min values in every dimension
    double m_mean[];
    double m_sigma[];
  
    int m_dimension;   // number of elements (columns) in every record = number of planes in the map
                       // special additional dimensions are added automatically, such as:
                       // Population (hit count), U-matrix (distances), Clusters, etc
    double m_dataMSE;
    bool m_initDone;
    bool m_allocated;
    
    double m_map_radius;
    double m_time_constant;
    double m_learning_rate;
    int m_iterations;
    string m_titles[];
    string m_set_titles[];
    bool m_hexCells;   // hexagonal cells
    string m_sID;      // object name prefix - TODO: optional setter needed

    double m_clusters[];
    string m_labels[];
    
    int m_validationOffset;
    ulong m_featureMask;
    int m_featureMaskSize;
    
    bool m_reframing;
    
  protected:
    virtual bool ReadCSVData(const int h);
    virtual int GetBestMatchingIndexNormalized(const double &vector[]) const;
    virtual int GetBestMatchingIndex(double &vector[]) const;
    virtual void InitNormalization(const bool normalization = true);
    virtual bool RemoveOutliers();
    virtual void Normalize(double &vector[]) const;
    virtual void Denormalize(double &vector[]) const;
    virtual double AddPatternStats(const double &vector[], const bool complete = true);
    virtual void AnalizePatternStats();
    virtual double CalculateStats(const bool complete = true);
    virtual bool ResetNodes();
    virtual void CalculateDataMSE(const bool complete = true);
    
  public:
    CSOM();
    ~CSOM();
    virtual bool Init(const int xc, const int yc, const bool bhex = true);
    virtual void Reset();
  
    // Data loading from csv (first line is a header, first column contains records' labels)
    bool LoadPatterns(const string filename);
    void Shuffle(); // random shuffling of patterns is important when validation is enabled
    void AddPattern(const double &vector[], const string title);
    bool GetPattern(const int index, double &vector[]) const;
    void AssignFeatureTitles(const string &titles[]);
    int GetDataCount() const { return m_nSet; }
    int GetFeatureCount() const { return m_dimension; }
    int GetWidth() const { return m_xcells; }
    int GetHeight() const { return m_ycells; }
    string GetFeatureTitle(const uint index) const { return index < (uint)ArraySize(m_titles) ? m_titles[index] : NULL; }
    string GetPatternTitle(const uint index) const { return index < (uint)ArraySize(m_set_titles) ? m_set_titles[index] : NULL; };
    int FindFeature(const string text) const;
    void GetFeatureBounds(const uint index, double &min, double &max) const { if(index < (uint)ArraySize(m_max)) { min = m_min[index]; max = m_max[index]; } else { min = max = 0; } }
  
    // Learning
    void SetValidationSection(const int splitOffset = 0);
    bool SetFeatureMask(const int dim, const ulong bitmask);
    double Train(const int epochs, const bool UseNormalization = true, const bool bShowProgress = false);
    double TrainAndReframe(const int epochs, const bool bUseNormalization = true, const bool bShowProgress = false, const int maxReframes = 10, const int xincrement = 1, const int yincrement = 1);
    virtual void Reframe(const int xincrement, const int yincrement); // growing SOM support stub
    virtual void CalculateDistances();
    virtual void Clusterize(const int clusterNumber);
    virtual int Clusterize();
    virtual int GetClusterCount() const;
    virtual void GetCluster(const int clusterNumber, double &center[]);
  
    int GetSize() const { return ArraySize(m_node); };
    CSOMNode *GetNode(const int index) const { return &m_node[index]; };
    CSOMNode *GetBestMatchingNode(const double &vector[]) const;
    bool GetBestMatchingFeatures(const int node, double &result[]) const;
    CSOMNode *GetBestMatchingFeatures(const double &vector[], double &result[]) const;
    virtual void CalculateOutput(const double &vector[], const bool normalize = false);
    virtual void SetLabel(const int cluster, const string label);
    
    bool Save(const string filename) const;
    bool Load(const string filename);
    string GetID() const { return m_sID; }
    
    virtual void ProgressUpdate() {};
    
    static string canonic(const string filename, const string ext);
    static string timestamp();
    
};


void CSOM::CSOM()
{
  Reset();
}

void CSOM::~CSOM()
{
  Reset();
}

void CSOM::Reset()
{
  m_initDone = false;
  m_allocated = false;
  m_sID = NULL;
  m_iterations = 100;
  m_learning_rate = 0.1;
  m_nSet = 0;
  m_dimension = 0;
  m_xcells = 0;
  m_ycells = 0;
  m_validationOffset = 0;
  m_featureMask = 0;
  m_featureMaskSize = 0;
  m_reframing = false;
  ArrayResize(m_set, 0);
  ArrayResize(m_titles, 0);
  ArrayResize(m_set_titles, 0);
  ArrayResize(m_node, 0);
  ArrayResize(m_clusters, 0);
  ArrayResize(m_labels, 0);
  CSOMNode::SetFeatureMask(0, 0);
}

static string CSOM::canonic(const string filename, const string ext)
{
  if(StringFind(filename, ext) != StringLen(filename) - 4)
  {
    return filename + ext;
  }
  return filename;
}

static string CSOM::timestamp()
{
  MqlDateTime mdt;
  TimeLocal(mdt);
  return StringFormat("-%04d%02d%02d-%02d%02d%02d", mdt.year, mdt.mon, mdt.day, mdt.hour, mdt.min, mdt.sec);
}

const string SIGNATURE = "MT5SOM.1";

bool CSOM::Save(const string filename) const
{
  int h = FileOpen(canonic(filename, FILE_EXT_SOM), FILE_BIN|FILE_WRITE);
  if(h != INVALID_HANDLE)
  {
    FileWriteString(h, SIGNATURE, StringLen(SIGNATURE) + 1);
    FileWriteInteger(h, StringLen(m_sID));
    FileWriteString(h, m_sID, StringLen(m_sID) + 1);
    FileWriteInteger(h, m_xcells);
    FileWriteInteger(h, m_ycells);
    FileWriteInteger(h, m_hexCells);
    FileWriteInteger(h, m_dimension);
    for(int i = 0; i < m_dimension; i++)
    {
      FileWriteInteger(h, StringLen(m_titles[i]));
      FileWriteString(h, m_titles[i], StringLen(m_titles[i]) + 1);
    }

    FileWriteArray(h, m_max);
    FileWriteArray(h, m_min);
    FileWriteArray(h, m_mean);
    FileWriteArray(h, m_sigma);

    FileWriteInteger(h, ArraySize(m_clusters));
    FileWriteArray(h, m_clusters);
    
    for(int i = 0; i < m_xcells * m_ycells; i++)
    {
      m_node[i].Save(h);
    }
    FileClose(h);
    Print("Map file ", canonic(filename, FILE_EXT_SOM), " saved");
    return true;
  }
  else
  {
   Print("FileOpen write failed ", GetLastError());
  }
  return false;
}

bool CSOM::Load(const string filename)
{
  bool result = false;
  int h = FileOpen(canonic(filename, FILE_EXT_SOM), FILE_BIN|FILE_READ|FILE_SHARE_READ|FILE_SHARE_WRITE);
  if(h != INVALID_HANDLE)
  {
    string t = FileReadString(h, StringLen(SIGNATURE) + 1);
    if(t == SIGNATURE)
    {
      int n = FileReadInteger(h);
      m_sID = FileReadString(h, n + 1);
      m_xcells = FileReadInteger(h);
      m_ycells = FileReadInteger(h);
      m_hexCells = FileReadInteger(h);
      m_dimension = FileReadInteger(h);
      ArrayResize(m_titles, m_dimension + EXTRA_DIMENSIONS);
      for(int i = m_dimension; i < m_dimension + EXTRA_DIMENSIONS; i++) m_titles[i] = extras[i - m_dimension];
      for(int i = 0; i < m_dimension; i++)
      {
        int len = FileReadInteger(h);
        m_titles[i] = FileReadString(h, len + 1);
      }
      
      FileReadArray(h, m_max, 0, m_dimension + EXTRA_DIMENSIONS);
      FileReadArray(h, m_min, 0, m_dimension + EXTRA_DIMENSIONS);
      
      FileReadArray(h, m_mean, 0, m_dimension);
      FileReadArray(h, m_sigma, 0, m_dimension);

      int nc = FileReadInteger(h);
      FileReadArray(h, m_clusters, 0, nc);
      
      CSOMNode::FactoryInit(m_dimension);
      ResetNodes();
      for(int i = 0; i < m_xcells * m_ycells; i++)
      {
        m_node[i].Load(h);
      }
      result = true;
      Print("Map file ", canonic(filename, FILE_EXT_SOM), " loaded");
      m_initDone = result;
      m_allocated = result;
    }
    else
    {
      Print("Unsupported file format");
    }
    FileClose(h);
  }
  else
  {
   Print("FileOpen read failed: ", canonic(filename, FILE_EXT_SOM), " ", GetLastError());
  }
  return result;
}


bool CSOM::Init(const int xc, const int yc, const bool bhex = true)
{
  if(m_initDone)
  {
    Print("Warning: The net is already initialized, Init skipped");
    return true;
  }
  
  m_hexCells = bhex;
  m_xcells = xc;
  m_ycells = yc;

  if(m_sID == NULL) m_sID = "SOM" + timestamp();

  m_initDone = true;
  
  CSOMNode::FactoryInit(m_dimension);
  return ResetNodes();
}

bool CSOM::ResetNodes()
{
  // make sure old objects (if any) are destroyed (invokes destructors)
  ArrayResize(m_node, 0);
  
  // allocate node array (every one with the given dimension) (invokes constructors)
  if(ArrayResize(m_node, m_xcells * m_ycells) == -1)
  {
    Print("ArrayResize failed: ", GetLastError());
    return false;
  }

  int ind = 0;
  for(int i = 0; i < m_xcells; i++)
  {
    for(int j = 0; j < m_ycells; j++)
    {
      m_node[ind++].InitNode(i, j);
    }
  }

  return true;
}

bool CSOM::LoadPatterns(const string filename)
{
  string fullname = canonic(filename, FILE_EXT_CSV);
  ResetLastError();
  int h = FileOpen(fullname, FILE_READ | FILE_ANSI);
  if(h == INVALID_HANDLE)
  {
    Print("FileOpen error ", fullname, " : ", GetLastError());
    return(false);
  }
  Print("FileOpen OK: ", fullname);
  bool rez = ReadCSVData(h);
  FileClose(h);
  m_sID = StringSubstr(fullname, 0, StringLen(fullname) - 4); // use name as prefix for object IDs
  return rez;
}

bool CSOM::ReadCSVData(const int h)
{
  string line[];
  int n = 0;
  while(!FileIsEnding(h))
  {
    string s = FileReadString(h);
    if(StringLen(s) <= 0) continue;
    n++;
    if(n > 1)
    {
      StringSplit(s, ';', line);
      double data[];
      int dim = ArraySize(line) - 1; 
      if(m_dimension != dim)
      {
        Print("Dimension error in ", n, " line");
        return false;
      }
      ArrayResize(data, dim);
      for(int i = 0; i < dim; i++) data[i] = StringToDouble(line[i + 1]);
      AddPattern(data, line[0]); // 0-th column is a label
    }
    else
    {
      // column names
      StringSplit(s, ';', line);
      int dim = ArraySize(line) - 1;
      if(dim == 0)
      {
        Print("The format of this CSV-file is not supported, expecting ';' as separator");
        return false;
      }
      if(m_initDone)
      {
        if(m_dimension > 0 && m_dimension != dim)
        {
          Print("Dimensions of initilized net and input data do not match each other: ", m_dimension, " vs ", dim);
          return false;
        }
      }
      m_dimension = dim;
      Print("HEADER: (", m_dimension + 1, ") ", s);
      ArrayResize(m_titles, m_dimension + EXTRA_DIMENSIONS);
      for(int i = 0; i < m_dimension; i++) m_titles[i] = line[i + 1];
      for(int i = m_dimension; i < m_dimension + EXTRA_DIMENSIONS; i++) m_titles[i] = extras[i - m_dimension];
    }
  }
  return true;
}

void CSOM::AddPattern(const double &vector[], const string title)
{
  m_nSet++;
  ArrayResize(m_set, m_dimension * m_nSet);
  ArrayResize(m_set_titles, m_nSet);
  m_set_titles[m_nSet - 1] = title;
  for(int i = 0; i < m_dimension; i++)
  {
    m_set[m_dimension * (m_nSet - 1) + i] = vector[i];
  }
}

bool CSOM::GetPattern(const int index, double &vector[]) const
{
  if(index >= 0 && index < m_nSet)
  {
    ArrayCopy(vector, m_set, 0, index * m_dimension, m_dimension);
    return true;
  }
  return false;
}

void CSOM::AssignFeatureTitles(const string &titles[])
{
  m_dimension = ArraySize(titles);
  ArrayResize(m_titles, m_dimension + EXTRA_DIMENSIONS);
  for(int i = 0; i < m_dimension; i++)
  {
    m_titles[i] = titles[i];
  }
  for(int i = m_dimension; i < m_dimension + EXTRA_DIMENSIONS; i++)
  {
    m_titles[i] = extras[i - m_dimension];
  }
}

int CSOM::FindFeature(const string text) const
{
  for(int i = 0; i < m_dimension; i++)
  {
    if(m_titles[i] == text) return i;
  }
  return -1;
}

bool CSOM::RemoveOutliers()
{
  int removed = 0;
  int size = ArraySize(m_set);

  for(int i = m_nSet - 1; i >= 0; i--)
  {
    for(int j = 0; j < m_dimension; j++)
    {
      double v = m_set[m_dimension * i + j];
      if(v < m_mean[j] - 3 * m_sigma[j]
      || v > m_mean[j] + 3 * m_sigma[j])
      {
#ifdef SOM_VERBOSE
        Print("Oulier ", i, " by ", m_titles[j], " removed: ", m_mean[j], ShortToString(0x00B1), m_sigma[j], " ", v);
#endif
#ifdef SOM_OUTLIERS_SOFT
        if(v < m_mean[j] - 3 * m_sigma[j])
        {
          m_set[m_dimension * i + j] = m_mean[j] - 3 * m_sigma[j];
        }
        else
        {
          m_set[m_dimension * i + j] = m_mean[j] + 3 * m_sigma[j];
        }
        
        removed++;
#else
        if(i < m_nSet - 1)
        {
          int tocopy = m_dimension * (m_nSet - i - 1 - removed);
          if(ArrayCopy(m_set, m_set, m_dimension * i, m_dimension * (i + 1), tocopy) != tocopy)
          {
            Print("ArrayCopy failed, copied elements: ");
          }
        }
        removed++;
        break;
#endif
      }
    }
  }
  if(removed > 0)
  {
#ifdef SOM_OUTLIERS_SOFT
    Print("Outliers edited to 3 sigma: ", removed);
#else
    if(m_validationOffset > 0)
    {
      double ratio = m_validationOffset * 1.0 / m_nSet;
      m_validationOffset = (int)((m_nSet - removed) * ratio);
    }
    ArrayResize(m_set, size - removed * m_dimension);
    m_nSet -= removed;
    Print("Outliers removed: ", removed, ", work vectors left: ", m_nSet, m_validationOffset > 0 ? (", new validation offset: " + (string)m_validationOffset): "");
#endif
  }
  else
  {
    Print("No outliers");
  }

  return removed > 0;
}

void CSOM::InitNormalization(const bool normalization = true)
{
  ArrayResize(m_max, m_dimension + EXTRA_DIMENSIONS);
  ArrayResize(m_min, m_dimension + EXTRA_DIMENSIONS);
  ArrayInitialize(m_max, 0);
  ArrayInitialize(m_min, 0);
  ArrayResize(m_mean, m_dimension);
  ArrayResize(m_sigma, m_dimension);
  m_allocated = true;

  for(int j = 0; j < m_dimension; j++)
  {
    double maxv = -DBL_MAX;
    double minv = +DBL_MAX;
    
    if(normalization)
    {
      m_mean[j] = 0;
      m_sigma[j] = 0;
    }
    
    for(int i = 0; i < m_nSet; i++)
    {
      double v = m_set[m_dimension * i + j];
      if(v > maxv) maxv = v;
      if(v < minv) minv = v;
      if(normalization)
      {
        m_mean[j] += v;
        m_sigma[j] += v * v;
      }
    }
    
    m_max[j] = maxv;
    m_min[j] = minv;
    
    if(normalization && m_nSet > 0)
    {
      m_mean[j] /= m_nSet;
      m_sigma[j] = MathSqrt(m_sigma[j] / m_nSet - m_mean[j] * m_mean[j]);
    }
    else
    {
      m_mean[j] = 0;
      m_sigma[j] = 1;
    }

#ifdef SOM_VERBOSE    
    Print(j, " ", m_titles[j], " min=", m_min[j], " max=", m_max[j], " mean=", m_mean[j], " sigma=", m_sigma[j]);
#endif
  }
}

bool CSOM::SetFeatureMask(const int dim, const ulong bitmask)
{
  if(dim < 0 || dim > m_dimension) return false;
  
  m_featureMask = 0;
  m_featureMaskSize = 0;
  if(bitmask != 0)
  {
    m_featureMask = bitmask;
    Print("Feature mask enabled:");
    for(int i = 0; i < m_dimension; i++)
    {
      if((bitmask & (1 << i)) != 0)
      {
        m_featureMaskSize++;
        Print(m_titles[i]);
      }
    }
  }
  else
  {
    for(int i = 0; i < dim; i++)
    {
      m_featureMask |= (1 << i);
    }
    m_featureMaskSize = dim;
  }
  CSOMNode::SetFeatureMask(dim == 0 ? m_dimension : dim, bitmask);
  return true;
}

void CSOM::SetValidationSection(const int splitOffset = 0)
{
  if(splitOffset < 0 || splitOffset >= m_nSet) return;
  m_validationOffset = splitOffset;
};

void CSOM::Shuffle()
{
  double temp[];
  ArrayResize(temp, m_dimension);
  string title;

  for(int i = 0; i < m_nSet; i++)
  {
    int ind1 = (int)(1.0 * m_nSet * rand() / 32768);
    int ind2 = (int)(1.0 * m_nSet * rand() / 32768);
    
    if(ind1 == ind2) continue;
    
    ArrayCopy(temp, m_set, 0, m_dimension * ind1, m_dimension);
    ArrayCopy(m_set, m_set, m_dimension * ind1, m_dimension * ind2, m_dimension);
    ArrayCopy(m_set, temp, m_dimension * ind2, 0, m_dimension);
    
    title = m_set_titles[ind1];
    m_set_titles[ind1] = m_set_titles[ind2];
    m_set_titles[ind2] = title;
  }
}

void CSOM::Reframe(const int xincrement, const int yincrement)
{
  m_xcells += xincrement;
  m_ycells += yincrement;
  m_reframing = true;
}

double CSOM::TrainAndReframe(const int epochs, const bool bUseNormalization = true, const bool bShowProgress = false, const int maxReframes = 10, const int xincrement = 1, const int yincrement = 1)
{
  double nmse = 0;
  double nextnmse = DBL_MAX;
  m_reframing = false;
  for(int i = 0; i < maxReframes; i++)
  {
    nmse = nextnmse;
    ResetNodes();
    nextnmse = Train(epochs, bUseNormalization, bShowProgress);
    if(nextnmse < nmse)
    {
      if(i < maxReframes - 1)
      {
        Reframe(xincrement, yincrement);
      }
      else
      {
        Print("Maximum reframe number reached ", maxReframes);
      }
    }
    else
    {
      Print("Exit map size increments due to increased MSE");
      break;
    }
  }
  return nextnmse;
}

double CSOM::Train(const int epochs, const bool bUseNormalization = true, const bool bShowProgress = false)
{
  if(bShowProgress) Print("Training ", m_xcells, "*", m_ycells, " ", (m_hexCells ? "hex" : "sqr"), " net starts");
  
  m_iterations = epochs;

  int iter = 0;  // epoch number
  double data[];
  ArrayResize(data, m_dimension);

  // calculate inital learning radius
  m_map_radius = MathMax(m_xcells, m_ycells) / 2.0;
  m_time_constant = 1.0 * m_iterations / MathLog(m_map_radius + 1);
#ifdef SOM_VERBOSE
  Print("m_time_constant=", m_time_constant);
#endif

  InitNormalization(bUseNormalization);
  if(bUseNormalization && !m_reframing/* && (m_validationOffset == 0)*/)
  {
    if(RemoveOutliers())
    {
      InitNormalization(bUseNormalization); // redo normalization if outliers were removed
    }
  }
  CalculateDataMSE(false); // this is a constant denominator for NMSE

  int trainingCount = m_validationOffset > 0 ? m_validationOffset : m_nSet;
  
  if(trainingCount <= 0)
  {
    Print("No data - no training");
    return 0;
  }
  
  int total_nodes = ArraySize(m_node);
  
  double nmse = 0;
  double nextnmse = 0;
  
  if(m_validationOffset > 0)
  {
    if(!m_reframing) Shuffle();
    nmse = CalculateStats(false);
  }
  
  static uint lastTick = GetTickCount();
  
  do
  {
    double neighbourhood_radius = m_map_radius * MathExp(-1.0 * iter / m_time_constant);
    double WS = neighbourhood_radius * neighbourhood_radius;
    double learning_rate = m_learning_rate * MathExp(-1.0 * iter / m_iterations); // decrease learning rate exponentially

    // one epoch means training on all patterns selected in random order
    for(int k = 0; k < trainingCount && !IsStopped(); k++)
    {
      int ind = (int)(1.0 * trainingCount * rand() / 32768); // choose a record from data set randomly
      
      ArrayCopy(data, m_set, 0, m_dimension * ind, m_dimension);
      int winningnode = GetBestMatchingIndex(data); // find a node closest to the record, data is normalized inplace inside
      if(winningnode == -1)
      {
        Print("bad node ", iter, " ", k);
        ArrayPrint(data);
      }
      bool odd = ((winningnode % m_ycells) % 2) == 1;
      for(int i = 0; i < total_nodes; i++)
      {
        bool odd_i = ((i % m_ycells) % 2) == 1;
        double shiftx = 0;
        
        if(m_hexCells && odd != odd_i)
        {
          if(odd && !odd_i)
          {
            shiftx = +0.5;
          }
          else // vice versa (!odd && odd_i)
          {
            shiftx = -0.5;
          }
        }

        // distance from the winner to i-th node
        double DistToNodeSqr = (m_node[winningnode].GetX() - (m_node[i].GetX() + shiftx)) * (m_node[winningnode].GetX() - (m_node[i].GetX() + shiftx))
                             + (m_node[winningnode].GetY() - m_node[i].GetY()) * (m_node[winningnode].GetY() - m_node[i].GetY());
        
        // the following line speeds up calculation at the expense
        // of greater granularity (artifacts) in the spatial distribution of features
        // if(DistToNodeSqr < 9 * WS) // it was 1 * WS, which is inappropriate for hexogonal grid
        {
          double influence = MathExp(-DistToNodeSqr / (2 * WS));
          m_node[i].AdjustWeights(data, learning_rate, influence);
        }
      }
    }

    
    if(m_validationOffset > 0 && iter >= m_iterations)
    {
      static int increaseCount = 0;
      
      nextnmse = CalculateStats(false);
      if(nextnmse < nmse)
      {
        nmse = nextnmse;
        increaseCount = 0;
      }
      else
      {
        increaseCount++;
        if(increaseCount > 1)
        {
          Print("Exit by validation error at iteration ", iter, "; NMSE[old]=", nmse, ", NMSE[new]=", nextnmse, ", set=", (m_nSet - m_validationOffset));
          break;
        }
      }
    }

    if(GetTickCount() - lastTick > 1000)
    {
      lastTick = GetTickCount();
      string comment;
      if(bShowProgress)
      {
        StringConcatenate(comment, "Pass ", iter, " from ", m_iterations, " ", (int)(iter * 100.0 / m_iterations), "%", (m_validationOffset > 0 && iter >= m_iterations ? " NMSE=" + (string)nextnmse : ""));
        Print(comment);
        Comment(comment);
#ifdef SOM_VERBOSE
        Print("L=", (float)learning_rate, " R=", (float)neighbourhood_radius);
#endif  
        ProgressUpdate();
      }
    }
    
    iter++;
  }
  while((iter < m_iterations || m_validationOffset > 0) && !IsStopped());

  nmse = CalculateStats();
  
  if(bShowProgress)
  {
    Print("Overall NMSE=", nmse);

    string comment;
    StringConcatenate(comment, (IsStopped() ? "Training cancelled" : ((m_validationOffset > 0 && iter >= m_iterations) ? "Training stopped by MSE" : "Training completed")), " at pass ", iter, ", NMSE=", nmse);
    Comment(comment);
    Print(comment);
  }
  
  // prepare for visualization
  AnalizePatternStats();
  
  return nmse;
}

void CSOM::Normalize(double &vector[]) const
{
  for(int k = 0; k < m_dimension; k++)
  {
    if(m_sigma[k] == 0)
    {
      /*
      static int component = -1;
      if(component != k)
      {
        Print("Sigma is 0 for component ", k, " of ", m_dimension, ", mean=", m_mean[k]);
        component = k;
      }
      */
    }
    else
    {
      vector[k] = (vector[k] - m_mean[k]) / m_sigma[k];
    }
  }
}

void CSOM::Denormalize(double &vector[]) const
{
  for(int k = 0; k < m_dimension; k++)
  {
    vector[k] = vector[k] * m_sigma[k] + m_mean[k];
  }
}

int CSOM::GetBestMatchingIndex(double &vector[]) const
{
  Normalize(vector); // vector is mutated due to (optional) normalization
  return GetBestMatchingIndexNormalized(vector);
}

CSOMNode *CSOM::GetBestMatchingNode(const double &vector[]) const
{
  double data[];
  ArrayCopy(data, vector);
  int index = GetBestMatchingIndex(data);
  if(index > -1)
  {
    return &m_node[index];
  }
  return NULL;
};

bool CSOM::GetBestMatchingFeatures(const int node, double &result[]) const
{
  if(node < 0 || node > ArraySize(m_node)) return false;
  m_node[node].GetCodeVector(result);
  Denormalize(result);
  return true;
}

CSOMNode *CSOM::GetBestMatchingFeatures(const double &vector[], double &result[]) const
{
  CSOMNode *node = GetBestMatchingNode(vector);
  if(node != NULL)
  {
    node.GetCodeVector(result);
    Denormalize(result);
  }
  return node;
}

int CSOM::GetBestMatchingIndexNormalized(const double &vector[]) const
{
  int min_ind = -1;
  double min_dist = DBL_MAX;
  int total_nodes = ArraySize(m_node);
  for(int i = 0; i < total_nodes; i++)
  {
    double d = m_node[i].CalculateDistance(vector);
    if(d < min_dist)
    {
      min_dist = d;
      min_ind = i;
    }
  }
  return min_ind;
}

double CSOM::AddPatternStats(const double &data[], const bool complete = true)
{
  static double vector[];
  ArrayCopy(vector, data);
  
  int ind = GetBestMatchingIndex(vector);
  
  // hits will allow us to calculate average (m) and sigma (s) for every cell in every plane/dimension
  // from n training patterns mapped to the cell,
  // then ShowPattern can display m, s, n in text marks
  // NB. when a cell W is winning, all neighbouring cells N with averages W(N)
  // laying inside W(m) +/- W(s) are candidates as well
  if(complete) m_node[ind].RegisterPatternHit(vector);
  
  double code[];
  m_node[ind].GetCodeVector(code);
  Denormalize(code);
  
  double mse = 0;
  int dimension = m_featureMask != 0 ? m_featureMaskSize : m_dimension;
  
  for(int i = 0; i < m_dimension; i++)
  {
    if(m_featureMask == 0 || ((m_featureMask & (1 << i)) != 0))
    {
      mse += (data[i] - code[i]) * (data[i] - code[i]);
    }
  }
  
  mse /= dimension;
  
  return mse;
}

template<typename T>
class Neighbourhood
{
  protected:
    int neighbours[];
    int nbhsize;
    bool hex;
    int m_ycells;

  public:
    Neighbourhood(const bool _hex, const int ysize)
    {
      hex = _hex;
      m_ycells = ysize;

      if(hex)
      {
        nbhsize = NBH_HEXAGONAL_SIZE;
        ArrayResize(neighbours, NBH_HEXAGONAL_SIZE);
        neighbours[0] = -1; // up (visually)
        neighbours[1] = +1; // down (visually)
        neighbours[2] = -m_ycells; // left
        neighbours[3] = +m_ycells; // right
        /* 4 & 5, applied dynamically in the loop below
        // odd row
        neighbours[4] = -m_ycells - 1; // left-up
        neighbours[5] = -m_ycells + 1; // left-down
        // even row
        neighbours[4] = +m_ycells - 1; // right-up
        neighbours[5] = +m_ycells + 1; // right-down
        */
      }
      else
      {
        nbhsize = NBH_SQUARE_SIZE;
        ArrayResize(neighbours, NBH_SQUARE_SIZE);
        neighbours[0] = -1; // up (visually)
        neighbours[1] = +1; // down (visually)
        neighbours[2] = -m_ycells; // left
        neighbours[3] = +m_ycells; // right
      }
    
    }
    ~Neighbourhood()
    {
      ArrayResize(neighbours, 0);
    }

    T loop(const int ind, const CSOMNode &p_node[])
    {
      int nodes = ArraySize(p_node);
      int j = ind % m_ycells;
      
      if(hex)
      {
        int oddy = ((j % 2) == 1) ? -1 : +1;
        neighbours[4] = oddy * m_ycells - 1;
        neighbours[5] = oddy * m_ycells + 1;
      }
      
      reset();

      for(int k = 0; k < nbhsize; k++)
      {
        if(ind + neighbours[k] >= 0 && ind + neighbours[k] < nodes)
        {
          // skip wrapping edges
          if(j == 0) // upper row
          {
            if(k == 0 || k == 4) continue;
          }
          else if(j == m_ycells - 1) // bottom row
          {
            if(k == 1 || k == 5) continue;
          }
          
          iterate(p_node[ind], p_node[ind + neighbours[k]]);
        }
      }
      
      return getResult();
    }
    
    virtual void reset() = 0;
    virtual void iterate(const CSOMNode &node1, const CSOMNode &node2) = 0;
    virtual T getResult() const = 0;
};

class UMatrixNeighbourhood: public Neighbourhood<double>
{
  private:
    int n;
    double d;
    
  public:
    UMatrixNeighbourhood(const bool _hex, const int ysize): Neighbourhood(_hex, ysize)
    {
    }
    
    virtual void reset() override
    {
      n = 0;
      d = 0.0;
    }
    
    virtual void iterate(const CSOMNode &node1, const CSOMNode &node2) override
    {
      d += node1.CalculateDistance(&node2);
      n++;
    }
    
    virtual double getResult() const override
    {
      return d / n;
    }
};

class ClusterNeighbourhood: public Neighbourhood<int>
{
  private:
    int cluster;
    double ridge;

  public:
    ClusterNeighbourhood(const bool _hex, const int ysize): Neighbourhood(_hex, ysize)
    {
    }
    
    virtual void reset() override
    {
      cluster = -1;
      ridge = DBL_MAX;
    }
    
    virtual void iterate(const CSOMNode &node1, const CSOMNode &node2) override
    {
      int x = node2.GetCluster();
      if(x > -1)
      {
        double y = node1.CalculateDistance(&node2);
        if(cluster == -1 || ((x < cluster) && (y < ridge || GlobalVariableCheck("SOM_NO_RIDGE"))))
        {
          cluster = x;
          ridge = y;
        }
      }
    }
    
    virtual int getResult() const override
    {
      return cluster;
    }
};

void CSOM::CalculateDistances()
{
  if(!m_allocated) return;
  
  UMatrixNeighbourhood umnh(m_hexCells, m_ycells);
  
  for(int i = 0; i < m_xcells * m_ycells; i++)
  {
    double d = umnh.loop(i, m_node);
    
    if(d > m_max[DIM_UMATRIX])
    {
      m_max[DIM_UMATRIX] = d;
    }
    
    m_node[i].SetDistance(d);
  }
}

void CSOM::CalculateOutput(const double &vector[], const bool normalize = false)
{
  if(!m_allocated) return;
  
  double temp[];
  ArrayCopy(temp, vector);
  if(normalize) Normalize(temp);
  m_min[DIM_OUTPUT] = DBL_MAX;
  m_max[DIM_OUTPUT] = -DBL_MAX;
  for(int i = 0; i < ArraySize(m_node); i++)
  {
    double x = m_node[i].CalculateOutput(temp);
    if(x < m_min[DIM_OUTPUT]) m_min[DIM_OUTPUT] = x;
    if(x > m_max[DIM_OUTPUT]) m_max[DIM_OUTPUT] = x;
  }
}

int CSOM::GetClusterCount() const
{
  return ArraySize(m_clusters) / m_dimension;
}

void CSOM::SetLabel(const int cluster, const string label)
{
  int nclusters = ArraySize(m_clusters) / m_dimension;
  if(ArraySize(m_labels) != nclusters) ArrayResize(m_labels, nclusters);
  if(cluster < nclusters)
  {
    m_labels[cluster] = label;
  }
}

int CSOM::Clusterize()
{
  double array[][2];
  int n = m_xcells * m_ycells;
  ArrayResize(array, n);
  for(int i = 0; i < n; i++)
  {
    if(m_node[i].GetHitsCount() > 0)
    {
      array[i][0] = m_node[i].GetDistance() * MathSqrt(m_node[i].GetMSE());
    }
    else
    {
      array[i][0] = DBL_MAX;
    }
    array[i][1] = i;
    m_node[i].SetCluster(-1);
  }
  ArraySort(array);
  
  ClusterNeighbourhood clnh(m_hexCells, m_ycells);

  int count = 0; // number of clusters
  ArrayResize(m_clusters, 0);
  
  for(int i = 0; i < n; i++)
  {
    // skip if already assigned
    if(m_node[(int)array[i][1]].GetCluster() > -1) continue;
    
    // check if current node is adjusent to any existing cluster
    int r = clnh.loop((int)array[i][1], m_node);
    if(r > -1) // a neighbour belongs to a cluster already
    {
      m_node[(int)array[i][1]].SetCluster(r);
    }
    else // we need new cluster
    {
      ArrayResize(m_clusters, (count + 1) * m_dimension);
      
      double vector[];
      m_node[(int)array[i][1]].GetCodeVector(vector);
      ArrayCopy(m_clusters, vector, count * m_dimension, 0, m_dimension);
      
      m_node[(int)array[i][1]].SetCluster(count++);
    }
  }
  return count;
}

void CSOM::GetCluster(const int clusterNumber, double &center[])
{
  ArrayCopy(center, m_clusters, 0, clusterNumber * m_dimension, m_dimension);
  Denormalize(center);
}

void CSOM::Clusterize(const int clusterNumber)
{
  int count = m_xcells * m_ycells;
  CMatrixDouble xy(count, m_dimension);
  int info;
  CMatrixDouble clusters;
  int membership[];
  double weights[];
  
  for(int i = 0; i < count; i++)
  {
    m_node[i].GetCodeVector(weights);
    xy[i] = weights;
  }

  CKMeans::KMeansGenerate(xy, count, m_dimension, clusterNumber, KMEANS_RETRY_NUMBER, info, clusters, membership);
  Print("KMeans result: ", info);
  if(info == 1) // ok
  {
    for(int i = 0; i < m_xcells * m_ycells; i++)
    {
      m_node[i].SetCluster(membership[i]);
    }
    
#ifdef SOM_VERBOSE
    Print("Clusters:");
#endif
    ArrayResize(m_clusters, clusterNumber * m_dimension);
    for(int j = 0; j < clusterNumber; j++)
    {
      for(int i = 0; i < m_dimension; i++)
      {
        m_clusters[j * m_dimension + i] = clusters[i][j];
      }
      
#ifdef SOM_VERBOSE
      ArrayPrint(m_clusters, _Digits, ",", j * m_dimension, m_dimension);
#endif
    }
  }
}

void CSOM::AnalizePatternStats()
{
  for(int i = 0; i < EXTRA_DIMENSIONS; i++)
  {
    m_min[m_dimension + i] = 0;
    m_max[m_dimension + i] = 0;
  }
  
  for(int i = 0; i < m_xcells * m_ycells; i++)
  {
    int n = m_node[i].GetHitsCount();
    if(n > m_max[DIM_HITCOUNT])
    {
      m_max[DIM_HITCOUNT] = n;
    }
    
    double u = m_node[i].GetMSE();
    if(n > 0 && u > 0)
    {
      if(u > m_max[DIM_NODEMSE])
      {
        m_max[DIM_NODEMSE] = (double)u;
      }
      if(u < m_min[DIM_NODEMSE] || m_min[DIM_NODEMSE] == 0)
      {
        m_min[DIM_NODEMSE] = (double)u;
      }
    }
    
    u = m_node[i].GetOutput();
    if(u > m_max[DIM_OUTPUT])
    {
      m_max[DIM_OUTPUT] = u;
    }
    if(u < m_min[DIM_OUTPUT] || m_min[DIM_OUTPUT] == 0)
    {
      m_min[DIM_OUTPUT] = (double)u;
    }
  }
}


void CSOM::CalculateDataMSE(const bool complete = true)
{
  double data[];
  int dimension = m_featureMask != 0 ? m_featureMaskSize : m_dimension;

  m_dataMSE = 0.0;
  
  for(int i = complete ? 0 : m_validationOffset; i < m_nSet; i++)
  {
    ArrayCopy(data, m_set, 0, m_dimension * i, m_dimension);

    double mse = 0;
    for(int k = 0; k < m_dimension; k++)
    {
      if(m_featureMask == 0 || ((m_featureMask & (1 << k)) != 0))
      {
        mse += (data[k] - m_mean[k]) * (data[k] - m_mean[k]);
      }
    }
    
    mse /= dimension;
    m_dataMSE += mse;
  }
}

double CSOM::CalculateStats(const bool complete = true)
{
  double data[];
  ArrayResize(data, m_dimension);
  double trainedMSE = 0.0;
  
  for(int i = complete ? 0 : m_validationOffset; i < m_nSet; i++)
  {
    ArrayCopy(data, m_set, 0, m_dimension * i, m_dimension);
    trainedMSE += AddPatternStats(data, complete);
  }
  
  if(complete && (m_validationOffset > 0)) CalculateDataMSE(); // update m_dataMSE
  
  const double nmse = trainedMSE / m_dataMSE;

  return nmse;
}
